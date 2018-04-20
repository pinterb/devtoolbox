### helm cli
# https://github.com/kubernetes/helm
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_helm()
{
  echo ""
  hdr "Installing helm CLI..."
  echo ""

  local install=0
  local release_url="https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VER}-linux-amd64.tar.gz"

  if command_exists helm; then
    if [ $(helm version | grep '^Client' | cut -d'"' -f2 2>/dev/null | grep "v${HELM_VER}") ]; then
      warn "helm is already installed."
      install=1
    else
      inf "helm is already installed...but versions don't match"
      exec_cmd '/usr/local/bin/helm reset'
      exec_cmd 'rm /usr/local/bin/helm'

      if [ -f "/usr/local/bin/tiller" ]; then
        exec_cmd 'rm /usr/local/bin/tiller'
      fi
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O /tmp/helm.tar.gz "$release_url"
    tar -zxvf /tmp/helm.tar.gz -C /tmp

    chmod +x "/tmp/linux-amd64/helm"
    exec_cmd "mv /tmp/linux-amd64/helm /usr/local/bin"

    rm /tmp/helm.tar.gz
    rm -rf "/tmp/linux-amd64"
    mark_as_installed helm
    echo ""
    echo ""
    inf "Be sure to run 'helm init' to (re-)install Tiller on your K8s cluster"
    echo ""
  fi
}


uninstall_helm()
{
  echo ""
  hdr "Uninstalling helm CLI..."
  echo ""

  if command_exists helm; then
    exec_cmd 'rm /usr/local/bin/helm'

    if [ -f "/usr/local/bin/tiller" ]; then
      exec_cmd 'rm /usr/local/bin/tiller'
    fi

    mark_as_uninstalled helm
  else
    warn "helm is not installed."
  fi
}

