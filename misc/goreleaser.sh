### GoReleaser
# https://goreleaser.com/
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_goreleaser()
{
  echo ""
  hdr "Installing GoReleaser..."
  echo ""

  local install=0

  if command_exists goreleaser; then
    if [ $(goreleaser --version | awk 'FNR == 2 { print $1; exit }') == "${GORELEASER_VER}*" ]; then
      warn "goreleaser is already installed."
      install=2
    else
      inf "goreleaser is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/goreleaser'
      install=1
    fi
  fi

  if [ $install -le 1 ]; then
    wget -O /tmp/goreleaser.tar.gz \
      "https://github.com/goreleaser/goreleaser/releases/download/v${GORELEASER_VER}/goreleaser_Linux_x86_64.tar.gz"
    tar zxvf /tmp/goreleaser.tar.gz -C /tmp

    chmod +x "/tmp/goreleaser"
    exec_cmd "mv /tmp/goreleaser /usr/local/bin"

    rm /tmp/goreleaser.tar.gz

    if [ "$DEFAULT_USER" == 'root' ]; then
      chown -R "$DEV_USER:$DEV_USER" /usr/local/bin
    else
      exec_cmd "chown root:root /usr/local/bin/goreleaser"
    fi

    mark_as_installed goreleaser
  fi
}


uninstall_goreleaser()
{
  echo ""
  hdr "Uninstalling GoReleaser..."
  echo ""

  local install=0

  if ! command_exists goreleaser; then
    warn "goreleaser is not installed."
  else
    exec_cmd 'rm /usr/local/bin/goreleaser'
  fi

  mark_as_uninstalled goreleaser
}
