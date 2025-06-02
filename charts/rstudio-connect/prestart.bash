#!/bin/bash
set -o errexit
set -o pipefail

main() {
  local startup_script="${1:-/usr/local/bin/startup.sh}"

  local cacert='/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'
  local k8s_url="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}"

  _logf 'Loading service account token'
  local sa_token
  sa_token="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

  _logf 'Checking kubernetes health via %s' "${k8s_url}"
  curl -fsSL \
    -H "Authorization: Bearer ${sa_token}" \
    --cacert "${cacert}" \
    "${k8s_url}/healthz" 2>&1 | _indent
  printf '\n'

  _logf 'Configuring certs'
  mkdir -p /usr/local/share/ca-certificates/Kubernetes
  cp -v "${cacert}" /usr/local/share/ca-certificates/Kubernetes/cert-Kubernetes.crt 2>&1 | _indent

  _logf 'Updating CA certificates'
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  DIST=$(cat /etc/os-release | grep "^ID=" -E -m 1 | cut -c 4-10 | sed 's/"//g')
  if [[ $DIST == "ubuntu" ]]; then
    update-ca-certificates 2>&1 | _indent
  elif [[ $DIST == "rhel" || $DIST == "almalinux" || $DIST == "rocky" ]]; then
    update-ca-trust 2>&1 | _indent
  fi

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
