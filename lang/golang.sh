### Golang
# https://golang.org
###

install_golang()
{
  echo ""
  hdr "Installing Golang.."
  echo ""

  local install=0

  if command_exists go; then
    if [ $(go version | awk '{ print $3; exit }') == "go$GOLANG_VER" ]; then
      warn "go is already installed"
      install=2
    else
      inf "go is already installed...but versions don't match"
      install=1
    fi
  fi

  if [ $install -le 1 ]; then
    git clone https://github.com/pinterb/install-golang.sh /tmp/install-golang
    source /tmp/install-golang/utils.sh

    if [ "$GOLANG_VER" == "$GOLANG_VERSION" ]; then
      exec_cmd '/tmp/install-golang/install-golang.sh'
    else
      error "expected golang version (i.e. $GOLANG_VER) doesn't match github.com/pinterb/install-golang.sh version (i.e. $GOLANG_VERSION)"
    fi

    # clean-up
    rm -rf /tmp/install-golang

    if [ "$DEFAULT_USER" == 'root' ]; then
      warn "the non-privileged user will need to create & set their own GOPATH"
    else
      local gopath=$(go env GOPATH 2> /dev/null || echo "/home/$DEV_USER/go")
      mkdir -p "$gopath/bin"
      mkdir -p "$gopath/src"
      mkdir -p "$gopath/pkg"

      if grep GOPATH "/home/$DEV_USER/.profile"; then
        inf "/home/$DEV_USER/.profile already modified with GOPATH"
      else

        # we don't want to overlay dot files after we modify .profile with GOPATH
        mark_dotprofile_as_touched golang

        inf "updating ~/.profile with GOPATH..."
        echo "" >> "/home/$DEV_USER/.profile"
        echo "# The following GOPATH was automatically added by $PROGDIR/$PROGNAME" >> "/home/$DEV_USER/.profile"
        echo "export GOPATH=$gopath" >> "/home/$DEV_USER/.profile"
        echo 'export PATH=$PATH:$GOPATH/bin' >> "/home/$DEV_USER/.profile"

        # User must log off for these changes to take effect
        LOGOFF_REQ=1
      fi # .profile contains GOPATH
    fi # DEFAULT_USER == root

    mark_as_installed golang
  fi # install or upgrade

}


uninstall_golang()
{
  echo ""
  hdr "Uninstalling Golang.."
  echo ""

  if command_exists go; then
    local gopath=$(go env GOPATH)

    git clone https://github.com/pinterb/install-golang.sh /tmp/install-golang
    exec_cmd '/tmp/install-golang/uninstall-golang.sh'
    rm -rf /tmp/install-golang

    exec_cmd "sed -i.gopath-bak '/GOPATH/d' /home/$DEV_USER/.profile"

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
