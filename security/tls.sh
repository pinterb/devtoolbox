###
# TLS utilities
###

install_tls()
{
  if function_exists install_cfssl; then
    install_cfssl
  else
    warn "cfssl install function doesn't exist."
  fi

  if function_exists install_letsencrypt; then
    install_letsencrypt
  else
    warn "letsencrypt install function doesn't exist."
  fi

  if function_exists install_certbot; then
    install_certbot
  else
    warn "certbot install function doesn't exist."
  fi

  install_manuale

  # lego install using "go get -u" doesn't seem to work.  And dependencies are
  # not defined in the project.
  #install_lego
}

uninstall_tls()
{
  if function_exists uninstall_cfssl; then
    uinstall_cfssl
  else
    warn "cfssl uninstall function doesn't exist."
  fi

  if function_exists uninstall_letsencrypt; then
    uninstall_letsencrypt
  else
    warn "letsencrypt uninstall function doesn't exist."
  fi

  if function_exists uninstall_certbot; then
    uninstall_certbot
  else
    warn "certbot uninstall function doesn't exist."
  fi

  uninstall_manuale

  # lego install using "go get -u" doesn't seem to work.  And dependencies are
  # not defined in the project.
  #uninstall_lego
}


### cfssl cli
# https://cfssl.org/
###
install_cfssl()
{
  echo ""
  inf "Installing CloudFlare's PKI toolkit..."
  echo ""

  if command_exists cfssl; then
    warn "cfssl is already installed."
  else
    wget -O /tmp/cfssl_linux-amd64 "https://pkg.cfssl.org/R${CFSSL_VER}/cfssl_linux-amd64"
    chmod +x /tmp/cfssl_linux-amd64
    exec_cmd 'mv /tmp/cfssl_linux-amd64 /usr/local/bin/cfssl'
  fi

  if command_exists cfssljson; then
    warn "cfssljson is already installed."
  else
    wget -O /tmp/cfssljson_linux-amd64 "https://pkg.cfssl.org/R${CFSSL_VER}/cfssljson_linux-amd64"
    chmod +x /tmp/cfssljson_linux-amd64
    exec_cmd 'mv /tmp/cfssljson_linux-amd64 /usr/local/bin/cfssljson'
  fi
}


uninstall_cfssl()
{
  echo ""
  inf "Uninstalling CloudFlare's PKI toolkit..."
  echo ""

  if command_exists cfssl; then
    exec_cmd 'rm /usr/local/bin/cfssl'
  else
    warn "cfssl is not installed."
  fi

  if command_exists cfssljson; then
    exec_cmd 'rm /usr/local/bin/cfssljson'
  else
    warn "cfssljson is not installed."
  fi
}


### manuaLE (A python Lets Encrypt client)
# https://github.com/veeti/manuale
###
install_manuale()
{
  echo ""
  inf "Installing manuaLE Lets Encrypt client..."
  echo ""

  if command_exists manuale; then
    local version="$(manuale --version)"
    warn "manuale cli is already installed...attempting upgrade"
    exec_cmd 'pip3 install --upgrade manuale'
  else
    exec_cmd 'pip3 install manuale'
  fi
}


uninstall_manuale()
{
  echo ""
  inf "Uninstalling manuaLE Lets Encrypt client..."
  echo ""

  if command_exists manuale; then
    local version="$(manuale --version)"
    warn "manuale cli is already installed...attempting upgrade"
    exec_cmd 'pip3 uninstall --yes manuale'
  else
    warn "cfssljson is not installed."
  fi
}



### lego (A golang Lets Encrypt client)
# https://github.com/xenolf/lego
###
install_lego()
{
  echo ""
  inf "Installing lego Lets Encrypt client..."
  echo ""

  if ! command_exists go; then
    warn "golang is required to install this utility.  But golang doesn't appear to be installed.  So skipping install"
  else
    rm -rf "$GOPATH/src/github.com/xenolf/lego"
    go get -u github.com/xenolf/lego
  fi
}
