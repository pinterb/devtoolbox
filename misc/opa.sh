### Open Policy Agent
# https://www.openpolicyagent.org/
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_opa()
{
  echo ""
  hdr "Installing opa.."
  echo ""

  local install=0

  local OPA_INSTALL_DIR="/usr/local/bin"
  local OPA_DOWNLOAD_DIR="/tmp"
  local OPA_DOWNLOAD_URL="https://github.com/open-policy-agent/opa/releases/download/v${OPA_VER}/opa_${HOSTOS}_${ARCH}"
  local OPA_DOWNLOADED_FILE="${OPA_DOWNLOAD_DIR}/opa"
  local TEST_GO_DIR="$GOPATH/src/github.com/pinterb"

  if command_exists opa; then
    local instver=$(opa version | awk '{ print $2; exit }')

    if [ "$instver" == "${OPA_VER}" ]; then
      warn "opa is already installed"
      install=2
    else
      inf "opa is already installed...but versions don't match"
      install=1
    fi
  fi

  if [ $install -le 1 ]; then

    if [ -f "${OPA_INSTALL_DIR}/opa" ]; then
      exec_cmd "rm -rf ${OPA_INSTALL_DIR}/opa"
    fi

    exec_cmd "rm -rf ${OPA_DOWNLOADED_FILE}"
    curl -L -o "${OPA_DOWNLOADED_FILE}" "${OPA_DOWNLOAD_URL}"
    exec_cmd "chmod +x ${OPA_DOWNLOADED_FILE}"
    exec_cmd "cp ${OPA_DOWNLOADED_FILE} ${OPA_INSTALL_DIR}/"

    mark_as_installed opa
  fi # install or upgrade

}


uninstall_opa()
{
  echo ""
  hdr "Uninstalling opa.."
  echo ""

  local OPA_INSTALL_DIR="/usr/local/bin"

  if command_exists opa; then

    if [ -f "$OPA_INSTALL_DIR/opa" ]; then
      echo ""
      exec_cmd "rm -rf $OPA_INSTALL_DIR/opa"
    fi

    mark_as_uninstalled opa
  else
    warn "opa is not installed"
  fi
}
