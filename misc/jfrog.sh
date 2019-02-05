### jfrog
# https://www.jfrog.com/confluence/display/CLI/JFrog+CLI
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

readonly BOOTSTRAP_JFROG_INST_DIR="/usr/local/bin"

install_jfrog()
{
  echo ""
  hdr "Installing JFrog cli..."
  echo ""

  local install=0
  local JFROG_INSTALL_DIR="/usr/local/bin"
  local JFROG_DOWNLOAD_DIR="/tmp"
  local JFROG_DOWNLOAD_URL="https://api.bintray.com/content/jfrog/jfrog-cli-go/${JFROG_VER}/jfrog-cli-${HOSTOS}-${ARCH}/jfrog?bt_package=jfrog-cli-${HOSTOS}-${ARCH}"
  local JFROG_DOWNLOADED_FILE="${JFROG_DOWNLOAD_DIR}/jfrog"


  if command_exists jfrog; then
    if [ $(jfrog --version | awk '{ print $3; exit }') == "$JFROG_VER" ]; then
      warn "jfrog is already installed"
      install=1
    else
      inf "jfrog is already installed...but versions don't match. Will update in-place..."
      install=2
      exec_cmd 'jfrog update'
    fi
  fi

  if [ $install -eq 0 ]; then

    if [ -f "${JFROG_INSTALL_DIR}/jfrog" ]; then
      exec_cmd "rm -rf ${JFROG_INSTALL_DIR}/jfrog"
    fi

    if [ -f "${JFROG_DOWNLOADED_FILE}" ]; then
      exec_cmd "rm -rf ${JFROG_DOWNLOADED_FILE}"
    fi

    exec_cmd "rm -rf ${JFROG_DOWNLOADED_FILE}"
    inf "downloading '${JFROG_DOWNLOAD_URL}'"
    curl -L -o "${JFROG_DOWNLOADED_FILE}" "${JFROG_DOWNLOAD_URL}"
    exec_cmd "chmod +x ${JFROG_DOWNLOADED_FILE}"
    exec_cmd "cp ${JFROG_DOWNLOADED_FILE} ${JFROG_INSTALL_DIR}/"

    mark_as_installed jfrog
  fi
}


uninstall_jfrog()
{
  echo ""
  hdr "Uninstalling JFrog cli..."
  echo ""

  local JFROG_INSTALL_DIR="/usr/local/bin"
  local JFROG_DOWNLOAD_DIR="/tmp"
  local JFROG_DOWNLOAD_URL="https://api.bintray.com/content/jfrog/jfrog-cli-go/${JFROG_VER}/jfrog-cli-${HOSTOS}.${ARCH}/jfrog?bt_package=jfrog-cli-${HOSTOS}.${ARCH}"
  local JFROG_DOWNLOADED_FILE="${JFROG_DOWNLOAD_DIR}/jfrog"

  if command_exists jfrog; then

    if [ -f "${JFROG_INSTALL_DIR}/jfrog" ]; then
      exec_cmd "rm -rf ${JFROG_INSTALL_DIR}/jfrog"
    fi

    if [ -f "${JFROG_DOWNLOADED_FILE}" ]; then
      exec_cmd "rm -rf ${JFROG_DOWNLOADED_FILE}"
    fi

    mark_as_uninstalled jfrog
  else
    warn "jfrog is not installed"
  fi
}

