### Kubebuilder
# https://kubernetes-sigs/kubebuilder/releases
# https://book.kubebuilder.io
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_kubebuilder()
{
  echo ""
  hdr "Installing kubebuilder.."
  echo ""

  local install=0
  local ARCH=amd64
  local KUBEBUILDER_INSTALL_DIR="/usr/local"
  local KUBEBUILDER_DOWNLOAD_DIR="/tmp"
  local KUBEBUILDER_DOWNLOAD_URL="https://github.com/kubernetes-sigs/kubebuilder/releases/download/v${KUBEBUILDER_VER}/kubebuilder_${KUBEBUILDER_VER}_linux_${ARCH}.tar.gz"
  local KUBEBUILDER_DOWNLOADED_FILE="${KUBEBUILDER_DOWNLOAD_DIR}/kubebuilder_${KUBEBUILDER_VER}_linux_${ARCH}.tar.gz"
  local TEST_GO_DIR="$GOPATH/src/github.com/pinterb"

  if ! command_exists go; then
    error "kubebuilder requires that golang be installed."
    error "golang does not appear to be installed."
  fi

  if command_exists kubebuilder; then
    local tmpver=$(cd $TEST_GO_DIR && kubebuilder version | awk '{ print $2 }' | awk -F':' '{ print $2 }' | awk -F',' '{ print $1; exit }')
    instver="${tmpver%\"}"
    instver="${instver#\"}"

    if [ "$instver" == "${KUBEBUILDER_VER}" ]; then
      warn "kubebuilder is already installed"
      install=2
    else
      inf "kubebuilder is already installed...but versions don't match"
      install=1
    fi
  fi

  if [ $install -le 1 ]; then

    if [ -d "${KUBEBUILDER_INSTALL_DIR}/kubebuilder" ]; then
      exec_cmd "rm -rf ${KUBEBUILDER_INSTALL_DIR}/kubebuilder"
    fi

    curl -L -o "${KUBEBUILDER_DOWNLOADED_FILE}" "${KUBEBUILDER_DOWNLOAD_URL}"
    cd /tmp && tar -zxvf "${KUBEBUILDER_DOWNLOADED_FILE}"
    exec_cmd "mv /tmp/kubebuilder_${KUBEBUILDER_VER}_linux_${ARCH} /usr/local/kubebuilder"

    # clean-up
    rm "${KUBEBUILDER_DOWNLOADED_FILE}"

    if [ "$DEFAULT_USER" == 'root' ]; then
      warn "the non-privileged user will need to create & set their own kubebuilder path"
    else
      inf "updating ~/.bootstrap/profile.d/ with kubebuilder path..."
      echo "# The following KUBEBLDRPATH was automatically added by $PROGDIR/$PROGNAME" > "/home/$DEV_USER/.bootstrap/profile.d/kubebuilder.sh"
      echo "" >> "/home/$DEV_USER/.bootstrap/profile.d/kubebuilder.sh"
      echo 'kubebldrinst=$(which kubebuilder)' >> "/home/$DEV_USER/.bootstrap/profile.d/kubebuilder.sh"
      echo 'if [ -z "$kubebldrinst" ]; then' >> "/home/$DEV_USER/.bootstrap/profile.d/kubebuilder.sh"
      echo '  export PATH=$PATH:/usr/local/kubebuilder/bin' >> "/home/$DEV_USER/.bootstrap/profile.d/kubebuilder.sh"
      echo 'fi' >> "/home/$DEV_USER/.bootstrap/profile.d/kubebuilder.sh"

      # User must log off for these changes to take effect
      LOGOFF_REQ=1
    fi

    mark_as_installed kubebuilder
  fi # install or upgrade

}


uninstall_kubebuilder()
{
  echo ""
  hdr "Uninstalling kubebuilder.."
  echo ""

  local KUBEBUILDER_INSTALL_DIR="/usr/local"

  if command_exists kubebuilder; then

    if [ -d "$KUBEBUILDER_INSTALL_DIR/kubebuilder" ]; then
      echo ""
      exec_cmd "rm -rf $KUBEBUILDER_INSTALL_DIR/kubebuilder"
    fi

    if [ -f "/home/$DEV_USER/.bootstrap/profile.d/kubebuilder.sh" ]; then
      exec_cmd "rm /home/$DEV_USER/.bootstrap/profile.d/kubebuilder.sh"
    fi

    if [ -f "/home/$DEV_USER/.bootstrap/touched-dotprofile/kubebuilder" ]; then
      exec_cmd "rm /home/$DEV_USER/.bootstrap/touched-dotprofile/kubebuilder"
    fi

    mark_as_uninstalled kubebuilder
  else
    warn "kubebuilder is not installed"
  fi
}
