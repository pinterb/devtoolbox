
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

  if [ -f "rm /etc/apt/sources.list.d/nodesource.save" ]; then
    exec_cmd 'rm /etc/apt/sources.list.d/nodesource.save'
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

  if [ -f "rm /etc/apt/sources.list.d/azure-cli.save" ]; then
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
    mark_as_uninstalled azure-cli
  else
    warn "docker-ce is not installed"
  fi

  if [ -f "/etc/docker/daemon.json" ]; then
    exec_cmd 'rm /etc/docker/daemon.json'
  fi

  if [ -f "/etc/apt/sources.list.d/docker.list" ]; then
    exec_cmd 'rm /etc/apt/sources.list.d/docker.list'
  fi

  if [ -f "rm /etc/apt/sources.list.d/docker.save" ]; then
    exec_cmd 'rm /etc/apt/sources.list.d/docker.save'
  fi

  if [ -f "/var/lib/docker" ]; then
    inf "NOTE: the \"/var/lib/docker\" directory was not deleted"
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



