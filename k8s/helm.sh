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
  local release_url="https://github.com/kubernetes/helm/releases/v${HELM_VER}"

  if command_exists helm; then
    if [ $(helm version | grep '^Client' | cut -d'"' -f2 2>/dev/null | grep "v${HELM_VER}") ]; then
      warn "helm is already installed."
      install=1
    else
      inf "helm is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/helm'

      if [ -f "/usr/local/bin/tiller" ]; then
        exec_cmd 'rm /usr/local/bin/tiller'
      fi
    fi
  fi

  if [ $install -eq 0 ]; then
    local helm_tag=$(wget -q -O - $release_url | awk '/\/tag\//' | grep -v no-underline | cut -d '"' -f 2 | awk '{n=split($NF,a,"/");print a[n]}' | awk 'a !~ $0{print}; {a=$0}')
    local helm_dist="helm-$helm_tag-linux-amd64.tar.gz"

    wget -O /tmp/helm.tar.gz \
      "https://kubernetes-helm.storage.googleapis.com/$helm_dist"
    tar -zxvf /tmp/helm.tar.gz -C /tmp
    exec_cmd 'cp /tmp/linux-amd64/helm /usr/local/bin/'
    rm /tmp/helm.tar.gz
    rm -rf "/tmp/linux-amd64"
    mark_as_installed helm
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

