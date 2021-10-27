#!/bin/bash
set -o errexit
set -o pipefail

main() {
  local startup_script="${1:-/usr/local/bin/startup.sh}"
  local dyn_dir='/mnt/dynamic/rstudio'

  local launcher_pem='/mnt/secret-configmap/rstudio/launcher.pem'
  local launcher_pub="${dyn_dir}/launcher.pub"

  _logf 'Ensuring %s exists' "${dyn_dir}"
  mkdir -p "${dyn_dir}"

  if [[ ! -s "${launcher_pub}" ]] && [[ -f "${launcher_pem}" ]]; then
    _logf 'Generating %s from %s' "${launcher_pub}" "${launcher_pem}"
    openssl rsa -in "${launcher_pem}" -outform PEM -pubout -out "${launcher_pub}" 2>&1 | _indent
    chmod -v 600 "${launcher_pub}" 2>&1 | _indent
  else
    _logf 'Ensuring %s does not exist' "${launcher_pub}"
    rm -vf "${launcher_pub}" 2>&1 | _indent
  fi

  _logf 'Preparing dirs'
  mkdir -p \
    /var/lib/rstudio-server/monitor/log \
  chown -v -R \
    rstudio-server:rstudio-server \
    /var/lib/rstudio-server 2>&1 | _indent

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
  format_string="$(printf '#----> prestart-workbench.bash %s: %s' "${now}" "${msg}")\\n"
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
