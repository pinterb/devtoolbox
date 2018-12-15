### Golang
# https://golang.org
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_golang()
{
  echo ""
  hdr "Installing Golang.."
  echo ""

  local install=0
  local GOLANG_INSTALL_DIR="/usr/local"
  local GOLANG_DOWNLOAD_DIR="/tmp"
  local GOLANG_DOWNLOAD_URL="https://storage.googleapis.com/golang/go$GOLANG_VER.linux-amd64.tar.gz"
  local GOLANG_DOWNLOADED_FILE="$GOLANG_DOWNLOAD_DIR/go$GOLANG_VER.linux-amd64.tar.gz"

  if command_exists go; then
    if [ $(go version | awk '{ print $3; exit }') == "go$GOLANG_VER" ]; then
      warn "go is already installed"
      install=2
    else
      inf "go is already installed...but versions don't match"
      install=1
    fi
  fi

  local wslgopath=$(echo "/home/$DEV_USER/go")
  if microsoft_wsl; then
    inf "This appears to be a Windows WSL distribution of Ubuntu. "
    #wslgopath=$(powershell.exe $PROGDIR/lang/golang.ps1)
    wslgopath="/mnt/c/projects/go"
    if [ ! -d "$wslgopath/bin" ]; then
      error "The GOPATH on windows (i.e. $wslgopath) doesn't appear to be set up correctly."
      #error "  Run powershell.exe $PROGDIR/lang/golang.ps1 -debug 1"
      exit 1
    fi
  fi

  if [ $install -le 1 ]; then

    if [ -d "$GOLANG_INSTALL_DIR/go" ]; then
      exec_cmd "rm -rf $GOLANG_INSTALL_DIR/go"
    fi

    curl -o "$GOLANG_DOWNLOADED_FILE" "$GOLANG_DOWNLOAD_URL"
    exec_cmd "tar -C /usr/local -xzf $GOLANG_DOWNLOADED_FILE"

    # clean-up
    rm "$GOLANG_DOWNLOADED_FILE"

    if [ "$DEFAULT_USER" == 'root' ]; then
      warn "the non-privileged user will need to create & set their own GOPATH"
    else
      local gopath=$(go env GOPATH 2> /dev/null || echo "/home/$DEV_USER/go")
      if microsoft_wsl; then
        gopath=$wslgopath
      else
        mkdir -p "$gopath/bin"
        mkdir -p "$gopath/src"
        mkdir -p "$gopath/pkg"
      fi

      inf "updating ~/.bootstrap/profile.d/ with GOPATH..."
      echo "# The following GOPATH was automatically added by $PROGDIR/$PROGNAME" > "/home/$DEV_USER/.bootstrap/profile.d/golang.sh"
      echo "" >> "/home/$DEV_USER/.bootstrap/profile.d/golang.sh"
      echo 'goinst=$(which go)' >> "/home/$DEV_USER/.bootstrap/profile.d/golang.sh"
      echo 'if [ -z "$goinst" ]; then' >> "/home/$DEV_USER/.bootstrap/profile.d/golang.sh"
      echo '  export PATH=$PATH:/usr/local/go/bin' >> "/home/$DEV_USER/.bootstrap/profile.d/golang.sh"
      echo "  export GOPATH=$gopath" >> "/home/$DEV_USER/.bootstrap/profile.d/golang.sh"
      echo '  export PATH=$PATH:$GOPATH/bin' >> "/home/$DEV_USER/.bootstrap/profile.d/golang.sh"
      echo 'fi' >> "/home/$DEV_USER/.bootstrap/profile.d/golang.sh"

      # User must log off for these changes to take effect
      LOGOFF_REQ=1
    fi

    mark_as_installed golang
  fi # install or upgrade

}


uninstall_golang()
{
  echo ""
  hdr "Uninstalling Golang.."
  echo ""

  local GOLANG_INSTALL_DIR="/usr/local"

  if command_exists go; then
    local gopath=$(go env GOPATH)

    if [ -d "$GOLANG_INSTALL_DIR/go" ]; then
      echo ""
      exec_cmd "rm -rf $GOLANG_INSTALL_DIR/go"
    fi

    if [ -f "/home/$DEV_USER/.bootstrap/profile.d/golang.sh" ]; then
      exec_cmd "rm /home/$DEV_USER/.bootstrap/profile.d/golang.sh"
    fi

    if [ -f "/home/$DEV_USER/.bootstrap/touched-dotprofile/golang" ]; then
      exec_cmd "rm /home/$DEV_USER/.bootstrap/touched-dotprofile/golang"
    fi

    if [ -d "$gopath" ]; then
      warn "the GOPATH: \"$gopath\" will not be deleted"
      warn "if you no longer want this directory, you'll need to remove it yourself"
    fi

    mark_as_uninstalled golang
  else
    warn "go is not installed"
  fi
}
