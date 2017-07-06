
### Golang
# https://golang.org
###
uninstall_golang()
{
  echo ""
  inf "Uninstalling Golang.."
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

  else
    warn "go is not installed."
  fi
}
