### Smallstep
# https://smallstep.com/
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_step()
{
  echo ""
  hdr "Installing smallstep utilities..."
  install_step_cli
  install_step_cert
}


uninstall_step()
{
  echo ""
  hdr "Uninstalling smallstep utilities..."
  uninstall_step_cli
  uninstall_step_cert
}


install_step_cli()
{
  echo ""
  hdr "  1. Installing step cli.."
  echo ""

  local install=0

  local STEP_DOWNLOAD_DIR="/tmp"
  local STEP_DOWNLOAD_URL="https://github.com/smallstep/cli/releases/download/v${STEP_CLI_VER}/step-cli_${STEP_CLI_VER}_amd64.deb"
  local STEP_DOWNLOADED_FILE="${STEP_DOWNLOAD_DIR}/step_${STEP_CLI_VER}_amd64.deb"

  if command_exists step; then
    local instver=$(step version | awk -F'/' '{ print $2; exit }' | awk -F'-' '{ print $1; exit }')

    if [ "$instver" == "${STEP_CLI_VER}" ]; then
      warn "step cli is already installed"
      install=2
    else
      inf "step cli is already installed...but versions don't match"
      install=1
    fi
  fi

  if [ $install -eq 1 ]; then
    uninstall_step_cli
  fi

  if [ $install -le 1 ]; then

    if [ -f "${STEP_DOWNLOADED_FILE}" ]; then
      exec_cmd "rm -rf ${STEP_DOWNLOADED_FILE}"
    fi

    curl -L -o "${STEP_DOWNLOADED_FILE}" "${STEP_DOWNLOAD_URL}"
    exec_cmd "dpkg -i ${STEP_DOWNLOADED_FILE}"

    mark_as_installed step-cli
  fi # install or upgrade

}


uninstall_step_cli()
{
  echo ""
  hdr "  1. Uninstalling step cli.."
  echo ""

  local STEP_DOWNLOAD_DIR="/tmp"
  local STEP_DOWNLOAD_URL="https://github.com/smallstep/cli/releases/download/v${STEP_CLI_VER}/step-cli_${STEP_CLI_VER}_amd64.deb"
  local STEP_DOWNLOADED_FILE="${STEP_DOWNLOAD_DIR}/step_${STEP_CLI_VER}_amd64.deb"


  if command_exists step; then
    if [ -f "${STEP_DOWNLOADED_FILE}" ]; then
      exec_cmd "rm -rf ${STEP_DOWNLOADED_FILE}"
    fi

    exec_cmd "dpkg -r step-cli"

    mark_as_uninstalled step-cli
  else
    warn "step cli is not installed"
  fi
}


install_step_cert()
{
  echo ""
  hdr "  2. Installing step cert.."
  echo ""

  local install=0

  local STEP_DOWNLOAD_DIR="/tmp"
  local STEP_DOWNLOAD_URL="https://github.com/smallstep/certificates/releases/download/v${STEP_CERT_VER}/step-certificates_${STEP_CERT_VER}_amd64.deb"
  local STEP_DOWNLOADED_FILE="${STEP_DOWNLOAD_DIR}/step-certificates_${STEP_CERT_VER}_amd64.deb"

  if command_exists step-ca; then
    local instver=$(step-ca version | awk -F'/' '{ print $2; exit }' | awk -F'-' '{ print $1; exit }')

    if [ "$instver" == "${STEP_CERT_VER}" ]; then
      warn "step ca is already installed"
      install=2
    else
      inf "step ca is already installed...but versions don't match"
      install=1
    fi
  fi

  if [ $install -eq 1 ]; then
    uninstall_step_cert
  fi

  if [ $install -le 1 ]; then

    if [ -f "${STEP_DOWNLOADED_FILE}" ]; then
      exec_cmd "rm -rf ${STEP_DOWNLOADED_FILE}"
    fi

    curl -L -o "${STEP_DOWNLOADED_FILE}" "${STEP_DOWNLOAD_URL}"
    exec_cmd "dpkg -i ${STEP_DOWNLOADED_FILE}"

    mark_as_installed step-cert
  fi # install or upgrade

}


uninstall_step_cert()
{
  echo ""
  hdr "  2. Uninstalling step cert.."
  echo ""

  local STEP_DOWNLOAD_DIR="/tmp"
  local STEP_DOWNLOAD_URL="https://github.com/smallstep/certificates/releases/download/v${STEP_CERT_VER}/step-certificates_${STEP_CERT_VER}_amd64.deb"
  local STEP_DOWNLOADED_FILE="${STEP_DOWNLOAD_DIR}/step-certificates_${STEP_CERT_VER}_amd64.deb"


  if command_exists step-ca; then
    if [ -f "${STEP_DOWNLOADED_FILE}" ]; then
      exec_cmd "rm -rf ${STEP_DOWNLOADED_FILE}"
    fi

    exec_cmd "dpkg -r step-certificates"

    mark_as_uninstalled step-cert
  else
    warn "step ca is not installed"
  fi
}
