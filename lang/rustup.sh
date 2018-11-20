### Rustup
# https://rustup.rs
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

# curl https://sh.rustup.rs -sSf | sh

install_rustup()
{
  echo ""
  hdr "Installing rustup..."
  echo ""

  local install=0

  if command_exists rustup; then
    if [ $(rustup --version | awk -F' ' '{ print $2; exit }') == "${RUSTUP_VER}" ]; then
      warn "rustup is already installed."
      install=2
    else
      inf "rustup is already installed...but versions don't match"
      install=1
    fi
  fi

  if [ $install -eq 1 ]; then
    inf "will attempt a rustup upgrade"
    exec_nonprv_cmd "rustup upgrade"
    exec_nonprv_cmd "rustup update stable"
  fi

  if [ $install -eq 0 ]; then
    rm -rf /tmp/rustup.sh
    wget -O /tmp/rustup.sh \
      "https://sh.rustup.rs"

    chmod +x "/tmp/rustup.sh"
    exec_nonprv_cmd "/tmp/rustup.sh"

    mark_as_installed rustup

  elif command_exists rustc; then
    if [ $(rustc --version | awk -F' ' '{ print $2; exit }') == "${RUSTC_VER}" ]; then
      warn "rustc is already up-to-date"
      install=2
    else
      inf "will attempt a rustc upgrade"
      exec_nonprv_cmd "rustup upgrade"
    fi
  fi
}


uninstall_rustup()
{
  echo ""
  hdr "Uninstalling rustup..."
  echo ""

  local install=0

  if ! command_exists rustup; then
    warn "rustup is not installed."
  else
    exec_nonprv_cmd "rustup self uninstall"
  fi

  mark_as_uninstalled rustup
}
