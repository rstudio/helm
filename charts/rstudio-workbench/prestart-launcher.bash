#!/bin/bash
set -o errexit
set -o pipefail

main() {
  local startup_script="${1:-/usr/lib/rstudio-server/bin/rstudio-launcher}"

  # Empty if enabled, set to "disabled" by default
  if [[ -z "${RSTUDIO_LAUNCHER_STARTUP_HEALTH_CHECK}" ]]; then
    local cacert='/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'
    local host="${KUBERNETES_SERVICE_HOST}"
    if [[ "${host}" == *:* ]]; then
      host="[${host}]"
    fi
    local k8s_url="https://${host}:${KUBERNETES_SERVICE_PORT}"

    _logf 'Loading service account token'
    local sa_token
    sa_token="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

    _logf 'Checking kubernetes health via %s' "${k8s_url}"
    # shellcheck disable=SC2086
    curl ${RSTUDIO_LAUNCHER_STARTUP_HEALTH_CHECK_ARGS} \
      -H "Authorization: Bearer ${sa_token}" \
      --cacert "${cacert}" \
      "${k8s_url}/livez?verbose" 2>&1 | _indent
    printf '\n'
  else
    _logf "Not checking kubernetes health because RSTUDIO_LAUNCHER_STARTUP_HEALTH_CHECK=${RSTUDIO_LAUNCHER_STARTUP_HEALTH_CHECK}"
    printf '\n'
  fi

  # Create the Local scratch dir setgid + group-writable (2775). In root mode this prestart runs as
  # root but the launcher drops to the non-root serviceAccountUser; the dir inherits the
  # rstudio-server group from the setgid parent, so the launcher can write to it via group
  # permission without any root-only ownership change. In rootless mode the process already
  # is serviceAccountUser. The Kubernetes scratch dir is mounted as an fsGroup-owned emptyDir by
  # the chart, so it arrives group-writable and must not be chmod-ed here (a non-owner chmod EPERMs).
  _logf 'Preparing dirs'
  install -d -m 2775 /var/lib/rstudio-launcher/Local

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
