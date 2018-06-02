### bosh cli
# https://bosh.io
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

install_bosh()
{
  echo ""
  hdr "Installing bosh CLI..."
  echo ""

  local install=0

  if ! function_exists bosh_deps_install; then
    error "bosh 'create-env' dependency install function doesn't exist."
    exit 1
  fi

  if command_exists bosh; then
    if [ $(bosh --version | awk '{ print $2; exit }' | awk -F- '{ print $1; exit }' 2>/dev/null | grep "${BOSH_VER}") ]; then
      warn "bosh is already installed."
      install=1
    else
      inf "bosh is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/bosh'
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O /tmp/bosh \
      "https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${BOSH_VER}-linux-amd64"

    local checksum=$(sha1sum /tmp/bosh | awk '{ print $1 }')
    if [ "$checksum" != "$BOSH_CHECKSUM" ]; then
      error "checksum verification failed:"
      error "  expected: $BOSH_CHECKSUM"
      error "    actual: $checksum"
      exit 1
    fi

    chmod +x /tmp/bosh
    exec_cmd 'mv /tmp/bosh /usr/local/bin/'

    if [ "$DEFAULT_USER" == 'root' ]; then
      chown -R "$DEV_USER:$DEV_USER" /usr/local/bin
    else
      exec_cmd "chown root:root /usr/local/bin/bosh"
    fi

    # install 'create-env' dependencies
    bosh_deps_install

    mark_as_installed bosh
  fi
}


uninstall_bosh()
{
  echo ""
  hdr "Uninstalling bosh CLI..."
  echo ""

  if command_exists bosh; then
    exec_cmd 'rm /usr/local/bin/bosh'
    mark_as_uninstalled bosh
  else
    warn "bosh is not installed."
  fi
}

