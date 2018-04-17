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

    if [ $(kubectl version | awk '{ print $5; exit }' | grep "$KUBE_VER") ]; then
      warn "kubectl is already installed."
      install=1
    else
      inf "kubectl is already installed...but versions don't match"
      exec_cmd "rm /home/$DEV_USER/bin/kube*"
    fi
  fi

  if [ $install -eq 0 ]; then

    curl -Lo "/tmp/kubectl" "https://storage.googleapis.com/kubernetes-release/release/${KUBE_VER}/bin/linux/amd64/kubectl"
    if [ -f /tmp/kubectl ]; then
      chmod +x /tmp/kubectl && \
      exec_cmd "mv /tmp/kubectl /usr/local/bin/kubectl"
    else
      error "expecting /tmp/kubectl to have been downloaded..."
      error "  but file was not found!"
      exit 1
    fi

    inf "updating ~/.bootstrap/profile.d/ with kubectl.."
    echo "# The following was automatically added by $PROGDIR/$PROGNAME" > "/home/$DEV_USER/.bootstrap/profile.d/kubectl.sh"
    echo "source <(kubectl completion bash)" >> "/home/$DEV_USER/.bootstrap/profile.d/kubectl.sh"

    if [ "$DEFAULT_USER" == 'root' ]; then
      chown -R "$DEV_USER:$DEV_USER" /usr/local/bin
    else
      exec_cmd "chown root:root /usr/local/bin/kubectl"
    fi

    mark_as_installed kubectl
  fi
}


uninstall_kubectl()
{
  echo ""
  hdr "Uninstalling kubectl CLI..."
  echo ""

  if command_exists minikube; then
    error "minikube is currently installed"
    error "...uninstall minikube before uninstalling kubectl"
    exit 1
  fi

  if command_exists kubectl; then
    exec_cmd "rm -f /usr/local/bin/kubectl*"

    if [ -f "/home/$DEV_USER/.bootstrap/profile.d/kubectl.sh" ]; then
      exec_cmd "rm /home/$DEV_USER/.bootstrap/profile.d/kubectl.sh"
    fi

    mark_as_uninstalled kubectl
  else
    warn "kubectl is not installed"
  fi
}

