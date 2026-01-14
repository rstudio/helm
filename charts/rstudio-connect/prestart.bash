#!/bin/bash
set -o errexit
set -o pipefail

kubernetes_health_check() {
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
}

configure_nameservice_module() {
  # Check if NSS Connect config file exists (mounted as a secret)
  if [[ ! -f "/etc/libnss_connect.conf" ]]; then
    _logf 'Nameservice config not found at /etc/libnss_connect.conf. Skipping nameservice setup'
    return 0
  fi

  _logf 'Found /etc/libnss_connect.conf mounted from secret'
  _logf 'Configuring nameservice module'

  cp /etc/nsswitch.conf /etc/nsswitch.conf.backup

  # Ensure required lines exist in nsswitch.conf
  # Default to 'files' which matches glibc's implicit default when a line is missing
  for db in passwd group initgroups; do
    grep -q "^${db}:" /etc/nsswitch.conf || echo "${db}: files" >> /etc/nsswitch.conf
  done

  # Add 'connect' module to each line
  sed -i \
    -e '/^passwd:/ { /connect/! s/$/ connect/ }' \
    -e '/^group:/ { /connect/! s/$/ connect/ }' \
    -e '/^initgroups:/ { /connect/! s/$/ connect/ }' \
    /etc/nsswitch.conf

  _logf 'Updated /etc/nsswitch.conf with connect module'

  # Run the nameservice activation script
  if [[ -x "/opt/rstudio-connect/extras/nameservice/activate-nameservice.sh" ]]; then
    /opt/rstudio-connect/extras/nameservice/activate-nameservice.sh
  else
    _logf 'WARNING: nameservice activation script not found or not executable'
  fi

  printf '\n'
}

main() {
  local startup_script="${1:-/usr/local/bin/startup.sh}"

  kubernetes_health_check
  configure_nameservice_module

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
