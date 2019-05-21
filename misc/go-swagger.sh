### go-swagger
# https://goswagger.io/install.html
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_goswagger()
{
  echo ""
  hdr "Installing go-swagger..."
  echo ""

  local install=0

  local GOSWAGGER_DOWNLOAD_DIR="/tmp"
  local GOSWAGGER_DOWNLOAD_URL="https://github.com/go-swagger/go-swagger/releases/download/v${GO_SWAGGER_VER}/swagger_${HOSTOS}_${ARCH}"
  local GOSWAGGER_DOWNLOADED_FILE="${GOSWAGGER_DOWNLOAD_DIR}/swagger"
  local GOSWAGGER_INSTALL_DIR="/usr/local/bin"

  if command_exists swagger; then
    local instver=$(swagger version | awk '{ print $2; exit }')

    if [ "$instver" == "v${GO_SWAGGER_VER}" ]; then
      warn "go-swagger cli is already installed"
      install=2
    else
      inf "go-swagger cli is already installed...but versions don't match"
      install=1
    fi
  fi

  if [ $install -eq 1 ]; then
    uninstall_goswagger
  fi

  if [ $install -le 1 ]; then

    if [ -f "${GOSWAGGER_DOWNLOADED_FILE}" ]; then
      exec_cmd "rm -rf ${GOSWAGGER_DOWNLOADED_FILE}"
    fi

    curl -L -o "${GOSWAGGER_DOWNLOADED_FILE}" "${GOSWAGGER_DOWNLOAD_URL}"
    chmod +x "${GOSWAGGER_DOWNLOADED_FILE}"
    exec_cmd "mv ${GOSWAGGER_DOWNLOADED_FILE} ${GOSWAGGER_INSTALL_DIR}/"

    mark_as_installed goswagger
  fi # install or upgrade

}


uninstall_goswagger()
{
  echo ""
  hdr "Uninstalling go-swagger..."
  echo ""

  local GOSWAGGER_DOWNLOAD_DIR="/tmp"
  local GOSWAGGER_DOWNLOAD_URL="https://github.com/go-swagger/go-swagger/releases/download/v${GO_SWAGGER_VER}/swagger_${HOSTOS}_${ARCH}"
  local GOSWAGGER_DOWNLOADED_FILE="${GOSWAGGER_DOWNLOAD_DIR}/swagger"
  local GOSWAGGER_INSTALL_DIR="/usr/local/bin"


  if command_exists swagger; then
    if [ -f "${GOSWAGGER_DOWNLOADED_FILE}" ]; then
      exec_cmd "rm -rf ${GOSWAGGER_DOWNLOADED_FILE}"
    fi

    exec_cmd "rm ${GOSWAGGER_INSTALL_DIR}/swagger"

    mark_as_uninstalled goswagger
  else
    warn "go-swagger is not installed"
  fi
}

