### krew
# https://github.com/GoogleContainerTools/krew
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_krew()
{
  echo ""
  hdr "Installing krew.."
  echo ""

  local install=0
  local ARCH=amd64
  local KREW_INSTALL_DIR="/usr/local"
  local KREW_DOWNLOAD_DIR="/tmp"
  local KREW_DOWNLOAD_URL="https://storage.googleapis.com/krew/v${KREW_VER}/krew.{tar.gz,yaml}"
  local KREW_DOWNLOADED_FILE="${KREW_DOWNLOAD_DIR}/krew_${KREW_VER}_linux_${ARCH}.tar.gz"
  local KREW_DOWNLOADED_FILE="krew.tar.gz"

  if [ -f "/home/$DEV_USER/.krew/bin/kubectl-krew" ]; then
    local tmpver=$(kubectl krew version | awk 'FNR==4{print $2}')
    instver="${tmpver%\"}"
    instver="${instver#\"}"

    if [ "$instver" == "v${KREW_VER}" ]; then
      warn "krew is already installed"
      install=2
    else
      inf "krew is already installed...but versions don't match"
      install=1
    fi
  fi

  if [ $install -le 1 ]; then

    if [ -d "${KREW_INSTALL_DIR}/krew" ]; then
      exec_cmd "rm -rf ${KREW_INSTALL_DIR}/krew"
    fi

    cd "${KREW_DOWNLOAD_DIR}" && curl -fsSLO "${KREW_DOWNLOAD_URL}"
    cd "${KREW_DOWNLOAD_DIR}" && tar -zxvf "${KREW_DOWNLOADED_FILE}"
    cd "${KREW_DOWNLOAD_DIR}" && ./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" install \
      --manifest=krew.yaml --archive=krew.tar.gz

    # clean-up
    cd "${KREW_DOWNLOAD_DIR}" && rm "${KREW_DOWNLOADED_FILE}" && rm krew.yaml

    if [ "$DEFAULT_USER" == 'root' ]; then
      warn "the non-privileged user will need to create & set their own krew path"
    else
      inf "updating ~/.bootstrap/profile.d/ with krew path..."
      echo "# The following KREWPATH was automatically added by $PROGDIR/$PROGNAME" > "/home/$DEV_USER/.bootstrap/profile.d/krew.sh"
      echo "" >> "/home/$DEV_USER/.bootstrap/profile.d/krew.sh"
      echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> "/home/$DEV_USER/.bootstrap/profile.d/krew.sh"

      # User must log off for these changes to take effect
      LOGOFF_REQ=1
    fi

    mark_as_installed krew
  fi # install or upgrade

}


uninstall_krew()
{
  echo ""
  hdr "Uninstalling krew.."
  echo ""

  local KREW_INSTALL_DIR="${KREW_ROOT:-$HOME/.krew}"

  if command_exists krew; then

    if [ -d "$KREW_INSTALL_DIR" ]; then
      echo ""
      exec_cmd "rm -rf $KREW_INSTALL_DIR"
    fi

    if [ -f "/home/$DEV_USER/.bootstrap/profile.d/krew.sh" ]; then
      exec_cmd "rm /home/$DEV_USER/.bootstrap/profile.d/krew.sh"
    fi

    if [ -f "/home/$DEV_USER/.bootstrap/touched-dotprofile/krew" ]; then
      exec_cmd "rm /home/$DEV_USER/.bootstrap/touched-dotprofile/krew"
    fi

    mark_as_uninstalled krew
  else
    warn "krew is not installed"
  fi
}
