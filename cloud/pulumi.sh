### Pulumi
# https://pulumi.io
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

# curl -fsSL https://get.pulumi.com | sh

install_pulumi()
{
  echo ""
  hdr "Installing pulumi..."
  echo ""

  local install=0

  if command_exists pulumi; then
    if [ $(pulumi version | awk '{ print $1; exit }') == "v$PULUMI_VER" ]; then
      warn "pulumi is already installed."
      install=2
    else
      inf "pulumi is already installed...but versions don't match"
      install=1
    fi
  fi

  if [ $install -eq 1 ]; then
    inf "will attempt a pulumi upgrade"
#    exec_nonprv_cmd "pulumi upgrade"
#    exec_nonprv_cmd "pulumi update stable"
echo "need a pulumi upgrade command"
  fi

  if [ $install -eq 0 ]; then
    rm -rf /tmp/pulumi.sh
    wget -O /tmp/pulumi.sh \
      "https://get.pulumi.com"

    chmod +x "/tmp/pulumi.sh"
    exec_nonprv_cmd "/tmp/pulumi.sh"

    mark_as_installed pulumi

  fi
}


uninstall_pulumi()
{
  echo ""
  hdr "Uninstalling pulumi..."
  echo ""

  local install=0

  if ! command_exists pulumi; then
    warn "pulumi is not installed."
  else
    exec_nonprv_cmd "rm -rf $HOME/.pulumi"
    sed -i".bak" '/pulumi/d' ~/.bashrc
    sed -i '/Pulumi/d' ~/.bashrc
  fi

  mark_as_uninstalled pulumi
}
