### Skaffold
# http://github.com/GoogleCloudPlatform/skaffold
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_skaffold()
{
  echo ""
  hdr "Installing Skaffold..."
  echo ""

  local install=0

  if command_exists skaffold; then
    if [ $(skaffold version | awk '{ print $1; exit }') == "v${SKAFFOLD_VER}" ]; then
      warn "skaffold is already installed."
      install=2
    else
      inf "skaffold is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/skaffold'
      install=1
    fi
  fi

  if [ $install -le 1 ]; then
    wget -O /tmp/skaffold \
      "https://storage.googleapis.com/skaffold/releases/v${SKAFFOLD_VER}/skaffold-linux-amd64"

    chmod +x "/tmp/skaffold"
    exec_cmd "mv /tmp/skaffold /usr/local/bin"

    if [ "$DEFAULT_USER" == 'root' ]; then
      chown -R "$DEV_USER:$DEV_USER" /usr/local/bin
    else
      exec_cmd "chown root:root /usr/local/bin/skaffold"
    fi

    mark_as_installed skaffold
  fi
}


uninstall_skaffold()
{
  echo ""
  hdr "Uninstalling Skaffold..."
  echo ""

  local install=0

  if ! command_exists skaffold; then
    warn "skaffold is not installed."
  else
    exec_cmd 'rm /usr/local/bin/skaffold'
  fi

  mark_as_uninstalled skaffold
}
