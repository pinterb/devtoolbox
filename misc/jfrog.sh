### jfrog
# https://www.jfrog.com/confluence/display/CLI/JFrog+CLI
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

readonly BOOTSTRAP_JFROG_INST_DIR="/usr/local/bin"

install_jfrog()
{
  echo ""
  hdr "Installing JFrog cli..."
  echo ""

  local install=0

  if command_exists jfrog; then
    if [ $(jfrog version | awk '{ print $3; exit }') == "$JFROG_VER" ]; then
      warn "jfrog is already installed"
      install=1
    else
      inf "jfrog is already installed...but versions don't match. Will update in-place..."
      install=2
      exec_cmd 'jfrog update'
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O /tmp/jfrog \
      "https://bintray.com/jfrog/jfrog-cli-go/jfrog-cli-linux-amd64/$JFROG_VER"
    exec_cmd "chmod +x /tmp/jfrog"
    exec_cmd "mv /tmp/jfrog $BOOTSTRAP_JFROG_INST_DIR/"
    mark_as_installed jfrog
  fi
}


uninstall_jfrog()
{
  echo ""
  hdr "Uninstalling JFrog cli..."
  echo ""

  if command_exists jfrog; then
    exec_cmd "rm $BOOTSTRAP_JFROG_INST_DIR/jfrog"
    mark_as_uninstalled jfrog
  else
    warn "jfrog is not installed"
  fi
}

