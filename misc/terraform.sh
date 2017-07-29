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

  if command_exists terraform; then
    if [ $(terraform version | awk '{ print $2; exit }') == "v$TERRAFORM_VER" ]; then
      warn "terraform is already installed."
      install=1
    else
      inf "terraform is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/terraform'
      mark_as_uninstalled terraform
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O /tmp/terraform.zip \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/terraform_${TERRAFORM_VER}_linux_amd64.zip"
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
}

