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

  _logf 'Checking kubernetes health via %s' "${k8s_url}"
  curl -fsSL \
    -H "Authorization: Bearer ${sa_token}" \
    --cacert "${cacert}" \
    "${k8s_url}/healthz" 2>&1 | _indent
  printf '\n'

  _logf "Setting env vars"
  export KUBERNETES_API_URL=${k8s_url}
  export KUBERNETES_AUTH_TOKEN=${sa_token}

  _logf 'Configuring certs'
  cp -v "${cacert}" ${dyn_dir}/k8s-cert 2>&1 | _indent
  mkdir -p /usr/local/share/ca-certificates/Kubernetes
  cp -v \
    ${dyn_dir}/k8s-cert \
    /usr/local/share/ca-certificates/Kubernetes/cert-Kubernetes.crt 2>&1 | _indent

  _logf 'Updating CA certificates'
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    update-ca-certificates 2>&1 | _indent

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

main "${@}"
