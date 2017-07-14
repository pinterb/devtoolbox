### ngrok
# https://ngrok.com
###


install_ngrok()
{
  echo ""
  hdr "Installing ngrok..."
  echo ""

  local install=0

  if command_exists ngrok; then
    if [ $(ngrok version | awk '{ print $3; exit }') == "$NGROK_VER" ]; then
      warn "ngrok is already installed"
      install=1
    else
      inf "ngrok is already installed...but versions don't match. Will update in-place..."
      install=2
      exec_cmd 'ngrok update'
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O /tmp/ngrok.zip \
      "https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip"
    exec_cmd 'unzip /tmp/ngrok.zip -d /usr/local/bin'
    mark_as_installed ngrok

    rm /tmp/ngrok.zip
  fi
}


uninstall_ngrok()
{
  echo ""
  hdr "Uninstalling ngrok..."
  echo ""

  if command_exists ngrok; then
    exec_cmd 'rm /usr/local/bin/ngrok'
    mark_as_uninstalled ngrok
  else
    warn "ngrok is not installed"
  fi
}

