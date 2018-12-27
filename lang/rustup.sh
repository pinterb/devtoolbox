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

    if [ ! -d "/home/$DEV_USER/.cargo/bin" ]; then
      err "What?? ~/.cargo/bin doesn't exist!! "
      err "...Fix this install script and try again "
      exit 1
    fi

    inf "updating ~/.bootstrap/profile.d/ with rustup env..."
    echo "# The following rustup path was automatically added by $PROGDIR/$PROGNAME" > "/home/$DEV_USER/.bootstrap/profile.d/rustup.sh"
    echo "" >> "/home/$DEV_USER/.bootstrap/profile.d/rustup.sh"
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "/home/$DEV_USER/.bootstrap/profile.d/rustup.sh"

    exec_nonprv_cmd "/home/$DEV_USER/.cargo/bin/rustup completions bash > /tmp/rustup.bash-completion"
    exec_cmd "cat /tmp/rustup.bash-completion > /etc/bash_completion.d/rustup.bash-completion"

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

    if [ -d "/home/$DEV_USER/.cargo" ]; then
      echo ""
      exec_cmd "rm -rf /home/$DEV_USER/.cargo"
    fi

    if [ -f "/home/$DEV_USER/.bootstrap/profile.d/rustup.sh" ]; then
      exec_cmd "rm /home/$DEV_USER/.bootstrap/profile.d/rustup.sh"
    fi

  fi

  mark_as_uninstalled rustup
}
