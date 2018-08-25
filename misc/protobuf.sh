### protocol buffers
# https://developers.google.com/protocol-buffers/
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_protobuf()
{
  echo ""
  hdr "Installing protocol buffers..."
  echo ""
  local install_proto=0

  if command_exists protoc; then
    if [ $(protoc --version | awk '{ print $2; exit }') == "v$PROTOBUF_VER" ]; then
      warn "protoc is already installed."
      install_proto=1
    else
      inf "protoc is already installed...but versions don't match"
    fi
  fi

  if [ $install_proto -eq 0 ]; then
    exec_cmd 'apt-get install -y autoconf automake libtool curl make g++ unzip >/dev/null'
    wget -O /tmp/protoc.tar.gz "https://github.com/google/protobuf/archive/v${PROTOBUF_VER}.tar.gz"
    tar -zxvf /tmp/protoc.tar.gz -C /tmp
    rm /tmp/protoc.tar.gz
    cd "/tmp/protobuf-${PROTOBUF_VER}" || exit 1
    ./autogen.sh
    ./configure
    make
#    make check

    if [ "$DEFAULT_USER" != 'root' ]; then
      exec_cmd 'make install'
      exec_cmd 'ldconfig'
    else
      exec_nonprv_cmd 'make install'
      exec_nonprv_cmd 'ldconfig'
    fi

    rm -rf "/tmp/linux-amd64"
    cd -
    mark_as_installed protobuf
  fi
}


uninstall_protobuf()
{
  echo ""
  hdr "Uninstalling protocol buffers..."
  echo ""

  if command_exists protoc; then
    local protobuf_inst=$(which protoc)
    exec_cmd "rm $protobuf_inst"
    mark_as_uninstalled protobuf
  else
    warn "protoc is not installed."
  fi
}

