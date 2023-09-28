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

  if [[ -n "$RSW_LOAD_BALANCING" ]]; then
    _logf "Enabling load-balancing by making sure that the /mnt/load-balancer/rstudio/load-balancer file exists"
    mkdir -p /mnt/load-balancer/rstudio/
    echo -e "delete-node-on-exit=1\nwww-host-name=$(hostname -i)" > /mnt/load-balancer/rstudio/load-balancer
  fi

  _logf 'Preparing dirs'
  mkdir -p \
    /var/lib/rstudio-server/monitor/log
  
  if [ -d "/var/lib/rstudio-server/Local" ]; then
    chown -v -R \
    rstudio-server:rstudio-server \
    /var/lib/rstudio-server/Local 2>&1 | _indent
  fi

  _writeEtcRstudioReadme

  # TODO: necessary until https://github.com/rstudio/rstudio-pro/issues/3638
  cp /mnt/configmap/rstudio/health-check /mnt/dynamic/rstudio/

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
