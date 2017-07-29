### kubectl cli
# http://kubernetes.io/docs/user-guide/prereqs/
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_kubectl()
{
  echo ""
  hdr "Installing kubectl CLI..."
  echo ""

  local install=0

  if command_exists kubectl; then
    local kubectl_loc=$(which kubectl)
    if [ "$kubectl_loc" == "/home/$DEV_USER/bin/google-cloud-sdk/bin/kubectl" ]; then
      error "it appears kubectl was installed using the google cloud sdk."
      error "if you want to install using this --kubectl option;"
      error "  then first uninstall gcloud version using 'gcloud components remove kubectl'"
      exit 1
    fi

    if [ $(kubectl version | awk '{ print $5; exit }' | grep "v$KUBE_VER") ]; then
      warn "kubectl is already installed."
      install=1
    else
      inf "kubectl is already installed...but versions don't match"
      exec_cmd "rm /home/$DEV_USER/bin/kube*"
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O "/tmp/kubernetes.tar.gz" \
      "https://github.com/kubernetes/kubernetes/releases/download/v${KUBE_VER}/kubernetes.tar.gz"
    tar -zxvf /tmp/kubernetes.tar.gz -C /tmp
    "/tmp/kubernetes/cluster/get-kube-binaries.sh"
    cp /tmp/kubernetes/client/bin/kube* "/home/$DEV_USER/bin/"

    rm /tmp/kubernetes.tar.gz
    rm -rf /tmp/kubernetes

    inf "updating ~/.bootstrap/profile.d/ with kubectl.."
    echo "# The following was automatically added by $PROGDIR/$PROGNAME" > "/home/$DEV_USER/.bootstrap/profile.d/kubectl.sh"
    echo "source <(kubectl completion bash)" >> "/home/$DEV_USER/.bootstrap/profile.d/kubectl.sh"
    mark_as_installed kubectl
  fi
}


uninstall_kubectl()
{
  echo ""
  hdr "Uninstalling kubectl CLI..."
  echo ""

  if command_exists kubectl; then
    exec_cmd "rm /home/$DEV_USER/bin/kube*"

    if [ -f "/home/$DEV_USER/.bootstrap/profile.d/kubectl.sh" ]; then
      exec_cmd "rm /home/$DEV_USER/.bootstrap/profile.d/kubectl.sh"
    fi

    mark_as_uninstalled kubectl
  else
    warn "kubectl is not installed"
  fi
}

