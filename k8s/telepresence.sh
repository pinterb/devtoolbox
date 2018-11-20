### Telepresence
# https://www.telepresence.io
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

#curl -s https://packagecloud.io/install/repositories/datawireio/telepresence/script.deb.sh | sudo bash
#sudo apt install --no-install-recommends telepresence

install_telepresence()
{
  echo ""
  hdr "Installing telepresence..."
  echo ""

  local install=0

  if command_exists telepresence; then
    if [ $(telepresence --version | awk '{ print $1; exit }') == "${TELEPRESENCE_VER}" ]; then
      warn "telepresence is already installed."
      install=2
    else
      inf "telepresence is already installed...but versions don't match"
      install=1
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O /tmp/telepresence.sh \
      "https://packagecloud.io/install/repositories/datawireio/telepresence/script.deb.sh"

    chmod +x "/tmp/telepresence.sh"
    if ! { sudo /tmp/telepresnce.sh 2>&1 ; } | grep -q 'Err:3 spacewalk.pg-dev.net'; then
      echo ""
    else
	    err "installing telepresnce deb package failed"
    fi

    if ! { sudo apt install --no-install-recommends telepresence 2>&1 ; } | grep -q 'Err:3 spacewalk.pg-dev.net'; then
      echo ""
    else
	    err "installing telepresnce failed"
    fi

    mark_as_installed telepresence

  elif [ $install -le 1 ]; then
    inf "attempting telepresence upgrade"

    if ! { sudo apt update 2>&1 ; } | grep -q 'Err:3 spacewalk.pg-dev.net'; then
      echo ""
    else
	    err "apt update failed"
    fi

    if ! { sudo apt install --no-install-recommends telepresence 2>&1 ; } | grep -q 'Err:3 spacewalk.pg-dev.net'; then
      echo ""
    else
	    err "upgrading telepresnce failed"
    fi

  fi
}


uninstall_telepresence()
{
  echo ""
  hdr "Uninstalling telepresence..."
  echo ""

  local install=0

  if ! command_exists telepresence; then
    warn "telepresence is not installed."
  else
    exec_cmd 'rm /usr/local/bin/telepresence'
  fi

  mark_as_uninstalled telepresence
}
