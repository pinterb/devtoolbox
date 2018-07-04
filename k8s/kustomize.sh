### kustomize
# http://github.com/kubernetes-sigs/kustomize
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_kustomize()
{
  echo ""
  hdr "Installing kustomize..."
  echo ""

  local install=0

  if command_exists kustomize; then
    if [ $(kustomize version | awk '{ print $1; exit }') == "v${KUSTOMIZE_VER}" ]; then
      warn "kustomize is already installed."
      install=2
    else
      inf "kustomize is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/kustomize'
      install=1
    fi
  fi

  if [ $install -le 1 ]; then
    wget -O /tmp/kustomize \
      "https://github.com/kubernetes-sigs/kustomize/releases/download/v${KUSTOMIZE_VER}/kustomize_${KUSTOMIZE_VER}_linux_amd64"

    chmod +x "/tmp/kustomize"
    exec_cmd "mv /tmp/kustomize /usr/local/bin"

    if [ "$DEFAULT_USER" == 'root' ]; then
      chown -R "$DEV_USER:$DEV_USER" /usr/local/bin
    else
      exec_cmd "chown root:root /usr/local/bin/kustomize"
    fi

    mark_as_installed kustomize
  fi
}


uninstall_kustomize()
{
  echo ""
  hdr "Uninstalling kustomize..."
  echo ""

  local install=0

  if ! command_exists kustomize; then
    warn "kustomize is not installed."
  else
    exec_cmd 'rm /usr/local/bin/kustomize'
  fi

  mark_as_uninstalled kustomize
}
