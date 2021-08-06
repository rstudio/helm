#!/bin/bash
set -o errexit
set -o pipefail

main() {
  local startup_script="${1:-/usr/local/bin/startup.sh}"
  local dyn_dir='/mnt/dynamic/rstudio'

  local cacert='/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'
  local k8s_url="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}"
  local launcher_k8s_conf="${dyn_dir}/launcher.kubernetes.conf"
  local launcher_pem='/mnt/secret-configmap/rstudio/launcher.pem'
  local launcher_pub="${dyn_dir}/launcher.pub"
  local launcher_ns="${RSTUDIO_LAUNCHER_NAMESPACE:-rstudio}"
  local lb_conf='/mnt/load-balancer/rstudio/load-balancer'

  _logf 'Loading service account token'
  local sa_token
  sa_token="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

  _logf 'Loading service account ca.crt'
  local ca_string
  ca_string="$(tr -d '\n' <"${cacert}" | base64 | tr -d '\n')"

  _logf 'Ensuring %s exists' "${dyn_dir}"
  mkdir -p "${dyn_dir}"

  if [[ "${PRESTART_LOAD_BALANCER_CONFIGURATION}" == enabled ]]; then
    _logf 'Generating %s' "${lb_conf}"
    cat >"${lb_conf}" <<EOF

[config]

balancer = sessions

[nodes]
$(hostname -i)
EOF
    _logf 'Current load-balancer file:'
    cat "${lb_conf}" | _indent
  fi

  if [[ ! -s "${launcher_pub}" ]] && [[ -f "${launcher_pem}" ]]; then
    _logf 'Generating %s from %s' "${launcher_pub}" "${launcher_pem}"
    openssl rsa -in "${launcher_pem}" -outform PEM -pubout -out "${launcher_pub}" 2>&1 | _indent
    chmod -v 600 "${launcher_pub}" 2>&1 | _indent
  else
    _logf 'Ensuring %s does not exist' "${launcher_pub}"
    rm -vf "${launcher_pub}" 2>&1 | _indent
  fi

  _logf 'Checking kubernetes health via %s' "${k8s_url}"
  curl -fsSL \
    -H "Authorization: Bearer ${sa_token}" \
    --cacert "${cacert}" \
    "${k8s_url}/healthz" 2>&1 | _indent
  printf '\n'

  _logf 'Generating %s' "${launcher_k8s_conf}"
  cat >"${launcher_k8s_conf}" <<EOF
api-url=${k8s_url}
auth-token=${sa_token}
kubernetes-namespace=${launcher_ns}
certificate-authority=${ca_string}
EOF

  _logf 'Configuring certs'
  cp -v "${cacert}" ${dyn_dir}/k8s-cert 2>&1 | _indent
  mkdir -p /usr/local/share/ca-certificates/Kubernetes
  cp -v \
    ${dyn_dir}/k8s-cert \
    /usr/local/share/ca-certificates/Kubernetes/cert-Kubernetes.crt 2>&1 | _indent

  _logf 'Updating CA certificates'
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    update-ca-certificates 2>&1 | _indent

  _logf 'Preparing dirs'
  mkdir -p \
    /var/lib/rstudio-server/monitor/log \
    /var/lib/rstudio-launcher/Local \
    /var/lib/rstudio-launcher/Kubernetes
  chown -v -R \
    rstudio-server:rstudio-server \
    /var/lib/rstudio-server \
    /var/lib/rstudio-launcher 2>&1 | _indent

  _writeEtcRstudioReadme

  _logf 'Replacing process with %s' "${startup_script}"
  exec "${startup_script}"
}

_logf() {
  local msg="${1}"
  shift
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%S)"
  local format_string
  format_string="$(printf '#----> prestart.bash %s: %s' "${now}" "${msg}")\\n"
  # shellcheck disable=SC2059
  printf "${format_string}" "${@}"
}

_indent() {
  sed -u 's/^/       /'
}

_writeEtcRstudioReadme() {
  _logf 'Writing README to empty /etc/rstudio directory'
  (cat <<$HERE$
The contents of this configuration directory have been moved to other directories
in order to facilitate running in Kubernetes. The directories are specified via
the XDG_CONFIG_DIRS environment variable defined in the Helm chart. The currently
defined directories are:

$(echo "$XDG_CONFIG_DIRS" | sed 's/:/\n/g')
$HERE$
  ) > /etc/rstudio/README
}

main "${@}"
