### draft
# https://github.com/kubernetes/helm
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

install_draft()
{
  echo ""
  hdr "Installing draft..."
  echo ""

  local install=0

  if ! command_exists minikube; then
    error "draft requires minikube. First install minikube and then re-try the installation of draft."
    exit 1
  fi

  if command_exists draft; then
    if [ $(draft version | awk -F: '{ print $3; exit }' | awk -F, '{ print $1; exit }' 2>/dev/null | grep "v${DRAFT_VER}") ]; then
      warn "draft is already downloaded."
      install=1
    else
      inf "draft is already downloaded...but versions don't match"
      exec_cmd 'rm /usr/local/bin/draft'
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O /tmp/draft.tar.gz \
      "https://azuredraft.blob.core.windows.net/draft/draft-v${DRAFT_VER}-linux-amd64.tar.gz"
    tar -zxvf /tmp/draft.tar.gz -C /tmp
    exec_cmd 'cp /tmp/linux-amd64/draft /usr/local/bin/'
    rm /tmp/draft.tar.gz
    rm -rf "/tmp/linux-amd64"

    warn "draft has been (re-)downloaded and extracted into your path."
    warn "  However, draft has not been installed. And installation is a bit more complicated than just dowloading."
    warn "  Go to https://github.com/Azure/draft/blob/v${DRAFT_VER}/docs/install.md to learn how to complete the installation."
  else
    warn "While draft has already been downloaded, it may not have been fully installed."
    warn "  And installation is a bit more complicated than just dowloading."
    warn "  Go to https://github.com/Azure/draft/blob/v${DRAFT_VER}/docs/install.md to learn how to complete the installation."
  fi
  mark_as_installed draft
}

uninstall_draft()
{
  echo ""
  hdr "Uninstalling draft..."
  echo ""

  if command_exists draft; then
    exec_cmd 'rm /usr/local/bin/draft'
    mark_as_uninstalled draft
  else
    warn "draft is not installed."
  fi
}
