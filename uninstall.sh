
### Golang
# https://golang.org
###
uninstall_golang()
{
  echo ""
  inf "Uninstalling Golang.."
  echo ""

  if command_exists go; then
    git clone https://github.com/pinterb/install-golang.sh /tmp/install-golang
    exec_cmd '/tmp/install-golang/uninstall-golang.sh'
    rm -rf /tmp/install-golang

    exec_cmd "sed -i.gopath-bak '/GOPATH/d' /home/$DEV_USER/.profile"

  else
    warn "go is not installed."
  fi
}
