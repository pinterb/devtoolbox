### Prototool
# https://www.gofi.sh
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_fish()
{
  echo ""
  hdr "Installing Fish..."
  echo ""

  local install=0
  local durl="https://raw.githubusercontent.com/fishworks/fish/master/scripts/install.sh"

  if command_exists gofish; then
      install=2
      warn "fish is already installed."
      exec_nonprv_cmd 'gofish install gofish'
      exec_nonprv_cmd 'gofish upgrade gofish'
  else
      install=1
  fi

  if [ -f "/tmp/fish.sh" ]; then
    rm -f "/tmp/fish.sh"
  fi

  if [ $install -le 1 ]; then
    wget -O /tmp/fish.sh "$durl"

    sudo bash /tmp/fish.sh

    if [ "$DEFAULT_USER" == 'root' ]; then
      chown -R "$DEV_USER:$DEV_USER" /usr/local/bin
    else
      exec_cmd "chown root:root /usr/local/bin/gofish"
    fi

    mark_as_installed fish

    echo ""
    echo ""
    inf "Run 'gofish init' to initialize your fish environment"
  fi
}


uninstall_fish()
{
  echo ""
  hdr "Uninstalling Fish..."
  echo ""

  local install=0

  if ! command_exists gofish; then
    warn "fish is not installed."
  else
      exec_cmd 'rm /usr/local/bin/fish'
  fi

  mark_as_uninstalled fish
}
