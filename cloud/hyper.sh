### hyper.sh
# https://www.hyper.sh/
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

install_hyper()
{
  echo ""
  hdr "Installing Hyper.sh..."
  echo ""

  if command_exists hyper; then
    warn "hyper is already installed...will re-install"
    exec_cmd 'rm /usr/local/bin/hyper'
  fi

  wget -O /tmp/hyper-linux.tar.gz \
    "https://hyper-install.s3.amazonaws.com/hyper-linux-x86_64.tar.gz"
  tar zxvf /tmp/hyper-linux.tar.gz -C /tmp

  chmod +x /tmp/hyper
  exec_cmd 'mv /tmp/hyper /usr/local/bin/hyper'
  rm /tmp/hyper-linux.tar.gz
  mark_as_installed hyper
}

uninstall_hyper()
{
  echo ""
  hdr "Uninstalling Hyper.sh..."
  echo ""

  if ! command_exists hyper; then
    warn "hyper is not installed"
  else
    exec_cmd 'rm /usr/local/bin/hyper'
  fi

  mark_as_uninstalled hyper
}
