### DigitalOcean doctl
# https://www.digitalocean.com/community/tutorials/how-to-use-doctl-the-official-digitalocean-command-line-client
###

install_doctl()
{
  echo ""
  hdr "Installing DigitalOcean doctl..."
  echo ""

  local install=0

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
    exec_nonprv_cmd "wget -O /tmp/doctl-linux.tar.gz https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VER}/doctl-${DOCTL_VER}-linux-amd64.tar.gz"
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


