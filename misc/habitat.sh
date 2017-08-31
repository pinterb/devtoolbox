### Habitat
# https://www.habitat.sh/docs/get-habitat/
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_habitat()
{
  echo ""
  hdr "Installing Habitat..."
  echo ""

  local install=0

  if command_exists hab; then
    if [ $(hab --version | awk '{ print $2; exit }') == "${HABITAT_VER}/${HABITAT_VER_TS}" ]; then
      warn "habitat is already installed."
      install=2
    else
      inf "habitat is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/hab'
      install=1
    fi
  fi

  if [ $install -le 1 ]; then
    wget -O /tmp/habitat.tar.gz \
      "https://bintray.com/habitat/stable/download_file?file_path=linux%2Fx86_64%2Fhab-${HABITAT_VER}-${HABITAT_VER_TS}-x86_64-linux.tar.gz"
    tar zxvf /tmp/habitat.tar.gz -C /tmp

    chmod +x "/tmp/hab-${HABITAT_VER}-${HABITAT_VER_TS}-x86_64-linux/hab"
    exec_cmd "mv /tmp/hab-${HABITAT_VER}-${HABITAT_VER_TS}-x86_64-linux/hab /usr/local/bin/hab"

    rm -rf "/tmp/hab-${HABITAT_VER}-${HABITAT_VER_TS}-x86_64-linux"
    rm /tmp/habitat.tar.gz

    # set up hab group and user.
    # also add non-privileged user to hab group
    if [ $install -eq 0 ]; then
      exec_cmd 'groupadd -f hab'
      inf "added hab group"
      echo ""
      exec_cmd "useradd -g hab hab"

      if [ "$DEFAULT_USER" == 'root' ]; then
        chown -R "$DEV_USER:$DEV_USER" /usr/local/bin
        usermod -a -G hab "$DEV_USER"
      else
        exec_cmd "usermod -aG hab $DEV_USER"
        inf "added $DEV_USER to group hab"
      fi

      # User must log off for these changes to take effect
      LOGOFF_REQ=1
    fi
  fi

  if [ "$DEFAULT_USER" == 'root' ]; then
    chown -R "$DEV_USER:$DEV_USER" /usr/local/bin
  else
    exec_cmd "chown root:root /usr/local/bin/hab"
  fi
  mark_as_installed habitat
}


uninstall_habitat()
{
  echo ""
  hdr "Uninstalling Habitat..."
  echo ""

  local install=0

  if ! command_exists hab; then
    warn "habitat is not installed."
  else
    exec_cmd 'rm /usr/local/bin/hab'
  fi

  mark_as_uninstalled habitat
}
