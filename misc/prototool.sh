### Prototool
# https://github.com/uber/prototool
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_prototool()
{
  echo ""
  hdr "Installing Prototool..."
  echo ""

  local install=0
  local durl="https://github.com/uber/prototool/releases/download/v${PROTOTOOL_VER}/prototool-$(uname -s)-$(uname -m)"

  if command_exists prototool; then
    if [ $(prototool version | awk '{ print $2; exit }') == "${PROTOTOOL_VER}" ]; then
      warn "prototool is already installed."
      install=2
    else
      inf "prototool is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/prototool'
      install=1
    fi
  fi

  if [ $install -le 1 ]; then
    wget -O /tmp/prototool "$durl"

    chmod +x "/tmp/prototool"
    exec_cmd "mv /tmp/prototool /usr/local/bin/prototool"

    if [ "$DEFAULT_USER" == 'root' ]; then
      chown -R "$DEV_USER:$DEV_USER" /usr/local/bin
    else
      exec_cmd "chown root:root /usr/local/bin/prototool"
    fi
    mark_as_installed prototool
  fi
}


uninstall_prototool()
{
  echo ""
  hdr "Uninstalling Prototool..."
  echo ""

  local install=0

  if ! command_exists prototool; then
    warn "prototool is not installed."
  else
      exec_cmd 'rm /usr/local/bin/prototool'
  fi

  mark_as_uninstalled prototool
}
