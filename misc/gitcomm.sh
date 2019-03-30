### gitcomm: Git commit message formatter
# https://github.com/karantin2020/gitcomm
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_gitcomm()
{
  echo ""
  hdr "Installing gitcomm..."
  echo ""

  local install=0

  local GITCOMM_DOWNLOAD_DIR="/tmp"
  local GITCOMM_DOWNLOAD_URL="https://github.com/karantin2020/gitcomm/releases/download/v${GITCOMM_VER}/gitcomm_${HOSTOS}_${ARCH}"
  local GITCOMM_DOWNLOADED_FILE="${GITCOMM_DOWNLOAD_DIR}/gitcomm"
  local GITCOMM_INSTALL_DIR="/usr/local/bin"

  if command_exists gitcomm; then
    local instver=$(gitcomm --version | awk '{ print $2; exit }')

    if [ "$instver" == "${GITCOMM_VER}" ]; then
      warn "gitcomm cli is already installed"
      install=2
    else
      inf "gitcomm cli is already installed...but versions don't match"
      install=1
    fi
  fi

  if [ $install -eq 1 ]; then
    uninstall_gitcomm
  fi

  if [ $install -le 1 ]; then

    if [ -f "${GITCOMM_DOWNLOADED_FILE}" ]; then
      exec_cmd "rm -rf ${GITCOMM_DOWNLOADED_FILE}"
    fi

    curl -L -o "${GITCOMM_DOWNLOADED_FILE}" "${GITCOMM_DOWNLOAD_URL}"
    chmod +x "${GITCOMM_DOWNLOADED_FILE}"
    exec_cmd "mv ${GITCOMM_DOWNLOADED_FILE} ${GITCOMM_INSTALL_DIR}/"

    mark_as_installed gitcomm
  fi # install or upgrade

}


uninstall_gitcomm()
{
  echo ""
  hdr "Uninstalling gitcomm..."
  echo ""

  local GITCOMM_DOWNLOAD_DIR="/tmp"
  local GITCOMM_DOWNLOAD_URL="https://github.com/karantin2020/gitcomm/releases/download/v${GITCOMM_VER}/gitcomm_${HOSTOS}_${ARCH}"
  local GITCOMM_DOWNLOADED_FILE="${GITCOMM_DOWNLOAD_DIR}/gitcomm"
  local GITCOMM_INSTALL_DIR="/usr/local/bin"


  if command_exists gitcomm; then
    if [ -f "${GITCOMM_DOWNLOADED_FILE}" ]; then
      exec_cmd "rm -rf ${GITCOMM_DOWNLOADED_FILE}"
    fi

    exec_cmd "rm ${GITCOMM_INSTALL_DIR}/gitcomm"

    mark_as_uninstalled gitcomm
  else
    warn "gitcomm is not installed"
  fi
}

