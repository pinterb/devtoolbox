### SDKMAN
# https://sdkman.io/
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

# curl -s "https://get.sdkman.io" | bash

install_sdkman()
{
  echo ""
  hdr "Installing sdkman..."
  echo ""

  local install=0

  if [ -f "$HOME/.sdkman/var/version" ]; then
    local ver=$(cat "$HOME/.sdkman/var/version")
    if [ "$ver" == "$SDKMAN_VER" ]; then
      warn "sdkman is already installed."
      install=2
    else
      inf "sdkman is already installed...but versions don't match"
      install=1
    fi
  fi

  if [ $install -eq 1 ]; then
    inf "will attempt a sdkman upgrade"
    exec_nonprv_cmd "source $HOME/.sdkman/bin/sdkman-init.sh && sdk selfupdate"
  fi

  if [ $install -eq 0 ]; then
    rm -rf /tmp/sdkman.sh
    wget -O /tmp/sdkman.sh \
      "https://get.sdkman.io"

    chmod +x "/tmp/sdkman.sh"
    exec_nonprv_cmd "/tmp/sdkman.sh"

    mark_as_installed sdkman

  fi
}


uninstall_sdkman()
{
  echo ""
  hdr "Uninstalling sdkman..."
  echo ""

  local install=0

  if ! command_exists sdk; then
    warn "sdkman is not installed."
  else
    exec_nonprv_cmd "rm -rf $HOME/.sdkman"
    sed -i".bak" '/sdkman/d' ~/.bashrc
    sed -i '/sdkman/d' ~/.bashrc
  fi

  mark_as_uninstalled sdkman
}
