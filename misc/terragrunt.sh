### terragrunt
# https://github.com/gruntwork-io/terragrunt
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_terragrunt()
{
  echo ""
  hdr "Installing terragrunt..."
  echo ""

  local install=0
  local durl="https://github.com/gruntwork-io/terragrunt/releases/download/$TERRAGRUNT_VER/terragrunt_linux_amd64"

  if command_exists terragrunt; then
    if [ $(terragrunt --version | awk '{ print $3; exit }') == "$TERRAGRUNT_VER" ]; then
      warn "terragrunt is already installed."
      install=1
    else
      inf "terragrunt is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/terragrunt'
      mark_as_uninstalled terragrunt
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O /tmp/terragrunt "$durl"
    chmod +x /tmp/terragrunt
    exec_cmd 'mv /tmp/terragrunt /usr/local/bin/'

    mark_as_installed terragrunt
  fi
}


uninstall_terragrunt()
{
  echo ""
  hdr "Uninstalling terragrunt..."
  echo ""

  if command_exists terragrunt; then
    exec_cmd 'rm /usr/local/bin/terragrunt'
    mark_as_uninstalled terragrunt
  else
    warn "terragrunt is not installed."
  fi

  if [ -d "/home/$DEV_USER/.terragrunt" ]; then
    warn "/home/$DEV_USER/terragrunt was removed"
    exec_cmd "rm -rf /home/$DEV_USER/.terragrunt"
  fi
}

