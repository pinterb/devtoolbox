### minikube
# https://github.com/kubernetes/minikube
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

install_minikube()
{
  echo ""
  hdr "Installing minikube..."
  echo ""

  local install=0

  if ! command_exists kubectl; then
    error "minikube requires kubectl. First install kubectl and then re-try the installation of minikube."
    exit 1
  fi

  if function_exists install_kvm; then
    install_kvm
  else
    error "attempting to install kvm as part of this minikube install. But the expected kvm install script was not found."
  fi
inf "hello"

  if command_exists minikube; then
    if [ $(minikube version | awk -F: '{ print $3; exit }' | awk -F, '{ print $1; exit }' 2>/dev/null | grep "v${MINIKUBE_VER}") ]; then
      warn "minikube is already installed."
      install=1
    else
      inf "minikube is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/minikube'
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O /tmp/minikube \
      "https://storage.googleapis.com/minikube/releases/v${MINIKUBE_VER}/minikube-linux-amd64"
    chmod +x /tmp/minikube
    exec_cmd 'mv /tmp/minikube /usr/local/bin/'
    inf " "
    inf "starting minikube..."
    minikube start --vm-driver=kvm2
  fi
  mark_as_installed minikube
}

uninstall_minikube()
{
  echo ""
  hdr "Uninstalling minikube..."
  echo ""

  if command_exists draft; then
    error "draft is currently installed"
    error "...uninstall draft before uninstalling minikube"
    exit 1
  fi

  if ! command_exists minikube; then
    warn "minikube is not installed."
  else
    exec_cmd 'rm /usr/local/bin/minikube'
    mark_as_uninstalled minikube
  fi
}
