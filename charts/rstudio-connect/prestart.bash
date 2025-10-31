#!/bin/bash
set -o errexit
set -o pipefail

main() {
  local startup_script="${1:-/usr/local/bin/startup.sh}"

  # ============================================================================
  # Kubernetes health check
  # ============================================================================

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

  # ============================================================================
  # Setup nameservice module
  # ============================================================================

  _logf 'Setting up Connect nameservice configuration'

  # Check if NSS Connect config file exists (mounted as secret)
  if [[ -f "/etc/libnss_connect.conf" ]]; then
    _logf 'Found /etc/libnss_connect.conf mounted from secret'

    # Modify nsswitch.conf to add 'connect' to passwd, group, and shadow lines
    cp /etc/nsswitch.conf /etc/nsswitch.conf.backup

    sed -i \
      -e '/^passwd:/ { /connect/! s/$/ connect/ }' \
      -e '/^group:/ { /connect/! s/$/ connect/ }' \
      -e '/^shadow:/ { /connect/! s/$/ connect/ }' \
      /etc/nsswitch.conf
    _logf 'Updated /etc/nsswitch.conf with connect module'

    # Run the nameservice activation script
    if [[ -x "/opt/rstudio-connect/extras/nameservice/activate-nameservice.sh" ]]; then
      /opt/rstudio-connect/extras/nameservice/activate-nameservice.sh
    else
      _logf 'WARNING: nameservice activation script not found or not executable'
    fi
  else
    _logf 'Nameservice config not found at /etc/libnss_connect.conf. Skipping nameservice setup'
  fi
  printf '\n'

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
