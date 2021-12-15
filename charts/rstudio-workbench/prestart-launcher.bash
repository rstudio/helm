#!/bin/bash
set -o errexit
set -o pipefail

main() {
  local startup_script="${1:-/usr/lib/rstudio-server/bin/rstudio-launcher}"
  local dyn_dir='/mnt/dynamic/rstudio'

  local cacert='/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'
  local k8s_url="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}"
  local launcher_k8s_conf="${dyn_dir}/launcher.kubernetes.conf"
  local launcher_ns="${RSTUDIO_LAUNCHER_NAMESPACE:-rstudio}"

  _logf 'Loading service account token'
  local sa_token
  sa_token="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

  _logf 'Loading service account ca.crt'
  local ca_string
  ca_string="$(tr -d '\n' <"${cacert}" | base64 | tr -d '\n')"

  _logf 'Ensuring %s exists' "${dyn_dir}"
  mkdir -p "${dyn_dir}"

  if [[ -z "${RSTUDIO_LAUNCHER_STARTUP_HEALTH_CHECK}" ]]; then
    _logf 'Checking kubernetes health via %s' "${k8s_url}"
    curl ${RSTUDIO_LAUNCHER_STARTUP_HEALTH_CHECK_ARGS} \
      -H "Authorization: Bearer ${sa_token}" \
      --cacert "${cacert}" \
      "${k8s_url}/livez?verbose" 2>&1 | _indent
    printf '\n'
  else
    _logf "Not checking kubernetes health because RSTUDIO_LAUNCHER_STARTUP_HEALTH_CHECK=${RSTUDIO_LAUNCHER_STARTUP_HEALTH_CHECK}"
    printf '\n'
  fi

  _logf 'Generating %s' "${launcher_k8s_conf}"
  cat >"${launcher_k8s_conf}" <<EOF
api-url=${k8s_url}
auth-token=${sa_token}
kubernetes-namespace=${launcher_ns}
certificate-authority=${ca_string}
use-templating=1
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
    /var/lib/rstudio-launcher/Local \
    /var/lib/rstudio-launcher/Kubernetes
  chown -v -R \
    rstudio-server:rstudio-server \
    /var/lib/rstudio-launcher 2>&1 | _indent

  _logf 'Replacing process with %s' "${startup_script}"
  exec "${startup_script}"
}

_logf() {
  local msg="${1}"
  shift
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%S)"
  local format_string
  format_string="$(printf '#----> prestart-launcher.bash %s: %s' "${now}" "${msg}")\\n"
  # shellcheck disable=SC2059
  printf "${format_string}" "${@}"
}

_indent() {
  sed -u 's/^/       /'
}

main "${@}"
