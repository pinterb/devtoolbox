### Terraform
# https://www.terraform.io/intro/getting-started/install.html
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_terraform()
{
  echo ""
  hdr "Installing Terraform..."
  echo ""

  local install=0
  local dver=$(echo $TERRAFORM_VER | awk -Fv '{print $2}')
  local durl="https://releases.hashicorp.com/terraform/${dver}/terraform_${dver}_linux_amd64.zip"

  if command_exists terraform; then
    if [ $(terraform version | awk '{ print $2; exit }') == "$TERRAFORM_VER" ]; then
      warn "terraform is already installed."
      install=1
    else
      inf "terraform is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/terraform'
      mark_as_uninstalled terraform
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O /tmp/terraform.zip "$durl"
    exec_cmd 'unzip /tmp/terraform.zip -d /usr/local/bin'

    rm /tmp/terraform.zip
    mark_as_installed terraform
  fi
}


uninstall_terraform()
{
  echo ""
  hdr "Uninstalling Terraform..."
  echo ""

  if command_exists terraform; then
    exec_cmd 'rm /usr/local/bin/terraform'
    mark_as_uninstalled terraform
  else
    warn "terraform is not installed."
  fi

  if [ -d "/home/$DEV_USER/.terraform.d" ]; then
    warn "/home/$DEV_USER/terraform.d was removed"
    exec_cmd "rm -rf /home/$DEV_USER/.terraform.d"
  fi
}

