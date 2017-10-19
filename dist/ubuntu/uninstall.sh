
# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


base_restore()
{
  echo ""
  inf "  restoring from base backup of packages, sources, keys, etc..."
  echo ""

  if [ -f "/home/$DEV_USER/.bootstrap/backup/$1/dotprofile" ]; then
    exec_cmd "cp /home/$DEV_USER/.bootstrap/backup/$1/dotprofile /home/$DEV_USER/.profile"
    exec_cmd "chown $DEV_USER:$DEV_USER /home/$DEV_USER/.profile"
  fi

  if [ -f "/home/$DEV_USER/.bootstrap/backup/$1/dotbash_profile" ]; then
    exec_cmd "cp /home/$DEV_USER/.bootstrap/backup/$1/dotbash_profile /home/$DEV_USER/.bash_profile"
    exec_cmd "chown $DEV_USER:$DEV_USER /home/$DEV_USER/.bash_profile"
  fi

  if [ -f "/home/$DEV_USER/.bootstrap/backup/$1/dotbashrc" ]; then
    exec_cmd "cp /home/$DEV_USER/.bootstrap/backup/$1/dotbashrc /home/$DEV_USER/.bashrc"
    exec_cmd "chown $DEV_USER:$DEV_USER /home/$DEV_USER/.bashrc"
  fi

  if [ -f "/home/$DEV_USER/.bootstrap/backup/$1/dotgitconfig" ]; then
    exec_cmd "cp /home/$DEV_USER/.bootstrap/backup/$1/dotgitconfig /home/$DEV_USER/.gitconfig"
    exec_cmd "chown $DEV_USER:$DEV_USER /home/$DEV_USER/.gitconfig"
  fi

  if [ -f "/home/$DEV_USER/.bootstrap/backup/$1/dotvimrc" ]; then
    exec_cmd "cp /home/$DEV_USER/.bootstrap/backup/$1/dotvimrc /home/$DEV_USER/.vimrc"
    exec_cmd "chown $DEV_USER:$DEV_USER /home/$DEV_USER/.vimrc"
  fi

  if [ -d "/home/$DEV_USER/.bootstrap/backup/$1/dotvim" ]; then
    exec_cmd "rm -rf /home/$DEV_USER/.vim"
    exec_cmd "cp -R /home/$DEV_USER/.bootstrap/backup/$1/dotvim /home/$DEV_USER/.vim"
    exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER/.vim"
  fi

  exec_cmd "apt-key add /home/$DEV_USER/.bootstrap/backup/$1/Repo.keys"
  exec_cmd "cp -R /home/$DEV_USER/.bootstrap/backup/$1/sources.list* /etc/apt/"
  exec_cmd "chmod +r /etc/apt/sources.list* -R"
  exec_cmd "apt-get update -y"
  exec_cmd "apt-get install dselect"
#  exec_cmd "dselect update"

  if [ -f "/home/$DEV_USER/.bootstrap/backup/$1/Package.list" ]; then
    exec_cmd "dpkg --clear-selections"
    exec_cmd "dpkg --set-selections < /home/$DEV_USER/.bootstrap/backup/$1/Package.list"
    exec_cmd "apt-get dselect-upgrade -y"
  fi

  mark_as_uninstalled basepkgs

  echo ""
}


uninstall_letsencrypt()
{
  echo ""
  inf "Uninstalling Lets Encrypt package for Ubuntu..."
  echo ""

  exec_cmd 'apt-get purge -yq letsencrypt >/dev/null 2>&1'
  exec_cmd 'apt-get autoremove -yq >/dev/null 2>&1'
  mark_as_uninstalled letsencrypt
  echo ""
}


### certbot
# https://certbot.eff.org/all-instructions/#ubuntu-16-04-xenial-none-of-the-above
###
uninstall_certbot()
{
  echo ""
  inf "Uninstalling certbot package for Ubuntu..."
  echo ""

  exec_cmd 'pip uninstall -y certbot-s3front >/dev/null 2>&1'
  exec_cmd 'apt-get purge -yq certbot >/dev/null 2>&1'
  exec_cmd 'apt-get autoremove -yq >/dev/null 2>&1'
  mark_as_uninstalled certbot

  local release=$(lsb_release -cs)

  if [ -f "/etc/apt/sources.list.d/certbot-ubuntu-certbot-$release.list" ]; then
    exec_cmd "rm /etc/apt/sources.list.d/certbot-ubuntu-certbot-$release.list"
  fi

  if [ -f "/etc/apt/sources.list.d/certbot-ubuntu-certbot-$release.save" ]; then
    exec_cmd "rm /etc/apt/sources.list.d/certbot-ubuntu-certbot-$release.save"
  fi

  echo ""
}


### node.js
# http://tecadmin.net/install-latest-nodejs-npm-on-ubuntu/#
###
uninstall_node()
{
  echo ""
  hdr "Uninstalling Node.js..."
  echo ""

  if command_exists serverless; then
    error "the serverless framework appears to be installed"
    error "...uninstall serverless before uninstalling node"
    exit 1
  fi

  if command_exists yarn; then
    exec_cmd 'npm uninstall -g yarn >/dev/null'
  else
    warn "yarn is not installed"
  fi

  if command_exists node; then
    exec_cmd 'apt-get purge -y nodejs >/dev/null'
    mark_as_uninstalled node
  else
    warn "node.js is not installed"
  fi

  if [ -f "/etc/apt/sources.list.d/nodesource.list" ]; then
    exec_cmd 'rm /etc/apt/sources.list.d/nodesource.list'
  fi

  if [ -f "/etc/apt/sources.list.d/nodesource.save" ]; then
    exec_cmd 'rm /etc/apt/sources.list.d/nodesource.save'
  fi

  if [ -d "/home/$DEV_USER/.npm" ]; then
    exec_cmd 'rm -rf /home/$DEV_USER/.npm'
  fi
}


uninstall_azure()
{
  echo ""
  hdr "Uninstalling Azure cli..."
  echo ""

  if command_exists az; then
    exec_cmd 'apt-get purge -y azure-cli >/dev/null'
    mark_as_uninstalled azurecli
  else
    warn "azure cli is not installed"
  fi

  if [ -f "/etc/apt/sources.list.d/azure-cli.list" ]; then
    exec_cmd 'rm /etc/apt/sources.list.d/azure-cli.list'
  fi

  if [ -f "/etc/apt/sources.list.d/azure-cli.save" ]; then
    exec_cmd 'rm /etc/apt/sources.list.d/azure-cli.save'
  fi
}


### docker
# https://docs.docker.com/engine/installation/linux/ubuntu/
# http://www.bretfisher.com/install-docker-ppa-on-ubuntu-16-04/
# https://www.ubuntuupdates.org/ppa/docker_new
###
uninstall_docker()
{
  echo ""
  hdr "Uninstalling Docker Community Edition..."
  echo ""

  if command_exists docker; then
    exec_cmd 'apt-get purge -yq docker-ce >/dev/null 2>&1'
    exec_cmd 'apt-get autoremove -yq >/dev/null 2>&1'
    mark_as_uninstalled docker
  else
    warn "docker-ce is not installed"
  fi

  if [ -f "/etc/docker/daemon.json" ]; then
    exec_cmd 'rm /etc/docker/daemon.json'
  fi

  if [ -f "/etc/apt/sources.list.d/docker.list" ]; then
    exec_cmd 'rm /etc/apt/sources.list.d/docker.list'
  fi

  if [ -f "/etc/apt/sources.list.d/docker.save" ]; then
    exec_cmd 'rm /etc/apt/sources.list.d/docker.save'
  fi

  if [ -f "/var/lib/docker" ]; then
    inf "NOTE: the \"/var/lib/docker\" directory was not deleted"
  fi

  if [ -f "/home/$DEV_USER/.bootstrap/profile.d/docker.sh" ]; then
    exec_cmd "rm /home/$DEV_USER/.bootstrap/profile.d/docker.sh"
  fi
}


### Uninstall the XFCE window manager
# https://xfce.org/
#
# NOTE: Currently, this is only intended for Ubuntu running from Windows' WSL (aka Bash on Windows)
###
uninstall_xfce()
{
  echo ""
  hdr "Uninstalling XFCE window manager..."
  echo ""

  if ! microsoft_wsl; then
    error "this doesn't appear to be a Windows WSL distribution of Ubuntu"
    exit 1
  fi

  exec_cmd 'apt-get purge -y realpath xfce4 >/dev/null'
  exec_cmd 'apt-get autoremove -yq >/dev/null 2>&1'
  mark_as_uninstalled xfce
}


### serverless
#
###
uninstall_serverless()
{
  echo ""
  hdr "Uninstalling serverless utilities..."
  echo ""

  if command_exists functions; then
    inf "google cloud functions emulator is installed. Will attempt to remove..."
    exec_cmd 'npm uninstall -g @google-cloud/functions-emulator >/dev/null'
  fi

  if command_exists up; then
    inf "up client is installed. Will attempt to remove..."
    if [ -f "/usr/local/bin/up" ]; then
      exec_cmd 'rm /usr/local/bin/up'
    else
      error "expecting up command to be located under /usr/local/bin"
      exit 1
    fi
  fi

  if command_exists apex; then
    inf "apex client is installed. Will attempt to remove..."
    if [ -f "/usr/local/bin/apex" ]; then
      exec_cmd 'rm /usr/local/bin/apex'
    else
      error "expecting apex command to be located under /usr/local/bin"
      exit 1
    fi
  fi

  if command_exists serverless; then
    inf "serverless client is installed. Will attempt to remove..."
    exec_cmd 'yarn global remove serverless >/dev/null'
  fi

  mark_as_uninstalled serverless
}


###
# https://code.visualstudio.com/docs/setup/linux
###
uninstall_vscode()
{
  echo ""
  hdr "Uninstalling Visual Studio Code IDE..."
  echo ""

  if command_exists code; then
    exec_cmd 'apt-get purge -y code >/dev/null'
    mark_as_uninstalled vscode
  else
    warn "Visual Studio Code is not installed."
  fi

  if [ -f "/etc/apt/sources.list.d/vscode.list" ]; then
    exec_cmd 'rm /etc/apt/sources.list.d/vscode.list'
  fi

  if [ -f "/etc/apt/trusted.gpg.d/microsoft.gpg" ]; then
    exec_cmd 'rm /etc/apt/trusted.gpg.d/microsoft.gpg'
  fi
}

