### Tilt
# https://tilt.build/
# https://github.com/windmilleng/tilt/releases
# https://docs.tilt.build/index.html
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_tilt()
{
  echo ""
  hdr "Installing tilt.."
  echo ""

  local install=0
  local ARCH=$(uname -m)
  local TILT_INSTALL_DIR="/usr/local/bin"
  local TILT_DOWNLOAD_DIR="/tmp"
  local TILT_DOWNLOAD_URL="https://github.com/windmilleng/tilt/releases/download/v${TILT_VER}/tilt.${TILT_VER}.${HOSTOS}.${ARCH}.tar.gz"
  local TILT_DOWNLOADED_FILE="${TILT_DOWNLOAD_DIR}/tilt_${TILT_VER}_${HOSTOS}_${ARCH}.tar.gz"

  if command_exists tilt; then
    local instver=$(tilt version | awk -F', ' '{ print $1; exit }' | awk -F',' '{ print $1; exit }')

    if [ "$instver" == "v${TILT_VER}" ]; then
      warn "tilt is already installed"
      install=2
    else
      inf "tilt is already installed...but versions don't match"
      install=1
    fi
  fi

  if [ $install -le 1 ]; then

    if [ -f "${TILT_INSTALL_DIR}/tilt" ]; then
      exec_cmd "rm -rf ${TILT_INSTALL_DIR}/tilt"
    fi

    if [ -f "${TILT_DOWNLOADED_FILE}" ]; then
      exec_cmd "rm -rf ${TILT_DOWNLOADED_FILE}"
    fi

    if [ -f "${TILT_DOWNLOAD_DIR}/tilt" ]; then
      exec_cmd "rm -rf ${TILT_DOWNLOAD_DIR}/tilt"
    fi

    curl -L -o "${TILT_DOWNLOADED_FILE}" "${TILT_DOWNLOAD_URL}"
    cd /tmp && tar -zxvf "${TILT_DOWNLOADED_FILE}"
    exec_cmd "cp /tmp/tilt ${TILT_INSTALL_DIR}/"

    # clean-up
    rm "${TILT_DOWNLOADED_FILE}"

    mark_as_installed tilt
  fi # install or upgrade

}


uninstall_tilt()
{
  echo ""
  hdr "Uninstalling tilt.."
  echo ""

  local ARCH=$(uname -m)
  local TILT_INSTALL_DIR="/usr/local/bin"
  local TILT_DOWNLOAD_DIR="/tmp"
  local TILT_DOWNLOAD_URL="https://github.com/windmilleng/tilt/releases/download/v${TILT_VER}/tilt.${TILT_VER}.${HOSTOS}.${ARCH}.tar.gz"
  local TILT_DOWNLOADED_FILE="${TILT_DOWNLOAD_DIR}/tilt_${TILT_VER}_${HOSTOS}_${ARCH}.tar.gz"


  if command_exists tilt; then

    if [ -f "${TILT_INSTALL_DIR}/tilt" ]; then
      exec_cmd "rm -rf ${TILT_INSTALL_DIR}/tilt"
    fi

    if [ -f "${TILT_DOWNLOADED_FILE}" ]; then
      exec_cmd "rm -rf ${TILT_DOWNLOADED_FILE}"
    fi

    if [ -f "${TILT_DOWNLOAD_DIR}/tilt" ]; then
      exec_cmd "rm -rf ${TILT_DOWNLOAD_DIR}/tilt"
    fi

    mark_as_uninstalled tilt
  else
    warn "tilt is not installed"
  fi
}
