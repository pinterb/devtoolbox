### Jenkins X
# http://jenkins-x.io/
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_jenkinsx()
{
  echo ""
  hdr "Installing Jenkins X..."
  echo ""

  local install=0

  if command_exists jx; then
    if [ $(jx version | awk 'FNR == 2 { print $2; exit }') == "${JENKINSX_VER}" ]; then
      warn "jenkins x is already installed."
      install=2
    else
      inf "jenkins x is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/jx'
      install=1
    fi
  fi

  if [ $install -le 1 ]; then
    wget -O /tmp/jenkinsx.tar.gz \
      "https://github.com/jenkins-x/jx/releases/download/v${JENKINSX_VER}/jx-linux-amd64.tar.gz"
    tar zxvf /tmp/jenkinsx.tar.gz -C /tmp

    chmod +x "/tmp/jx"
    exec_cmd "mv /tmp/jx /usr/local/bin/jx"

    rm /tmp/jenkinsx.tar.gz
    mark_as_installed jenkinsx
  fi
}


uninstall_jenkinsx()
{
  echo ""
  hdr "Uninstalling Jenkins X..."
  echo ""

  local install=0

  if ! command_exists jx; then
    warn "jenkins x is not installed."
  else
    exec_cmd 'rm /usr/local/bin/jx'
  fi

  mark_as_uninstalled jenkinsx
}
