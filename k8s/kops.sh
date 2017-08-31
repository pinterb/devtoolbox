### kops
# https://github.com/kubernetes/kops#linux
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

install_kops()
{
  echo ""
  hdr "Installing Kubernetes Kops..."
  echo ""

  if ! command_exists terraform; then
    error "kops leverages terraform for some use cases"
    error "...first install terraform and then try again."
    exit 1
  fi

  if command_exists kops; then
    warn "kops is already installed...will re-install"
    exec_cmd 'rm /usr/local/bin/kops'
  fi

  wget -O /tmp/kops "https://github.com/kubernetes/kops/releases/download/${KOPS_VER}/kops-linux-amd64"
  chmod +x /tmp/kops
  exec_cmd 'mv /tmp/kops /usr/local/bin/kops'
  mark_as_installed kops
}


uninstall_kops()
{
  echo ""
  hdr "Uninstalling Kubernetes Kops..."
  echo ""

  if ! command_exists kops; then
    warn "kops is not installed"
  else
    exec_cmd 'rm /usr/local/bin/kops'
  fi
  mark_as_uninstalled kops

}
