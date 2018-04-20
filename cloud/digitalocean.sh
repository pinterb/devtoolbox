### DigitalOcean doctl
# https://www.digitalocean.com/community/tutorials/how-to-use-doctl-the-official-digitalocean-command-line-client
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_doctl()
{
  echo ""
  hdr "Installing DigitalOcean doctl..."
  echo ""

  local install=0
  local dver=$(echo $DOCTL_VER | awk -Fv '{print $2}')
  local durl="https://github.com/digitalocean/doctl/releases/download/${DOCTL_VER}/doctl-${dver}-linux-amd64.tar.gz"

  if command_exists doctl; then
    if [ $(doctl version | awk '{ print $3; exit }') == "${DOCTL_VER}-release" ]; then
      warn "doctl is already installed"
      install=1
    else
      inf "doctl is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/doctl'
    fi
  fi

  if [ $install -eq 0 ]; then
    exec_nonprv_cmd "wget -O /tmp/doctl-linux.tar.gz ${durl}"
    exec_nonprv_cmd "tar zxvf /tmp/doctl-linux.tar.gz -C /tmp"
    exec_nonprv_cmd "chmod +x /tmp/doctl"
    exec_cmd 'mv /tmp/doctl /usr/local/bin/doctl'
    exec_nonprv_cmd "rm /tmp/doctl-linux.tar.gz"
    mark_as_installed doctl
  fi
}


uninstall_doctl()
{
  echo ""
  hdr "Uninstalling DigitalOcean doctl..."
  echo ""

  if command_exists doctl; then
    exec_cmd 'rm /usr/local/bin/doctl'
    mark_as_uninstalled doctl
  else
    warn "doctl is not installed"
  fi
}


