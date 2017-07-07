
# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


uninstall_letsencrypt()
{
  echo ""
  inf "Uninstalling Lets Encrypt package for Ubuntu..."
  echo ""

  exec_cmd 'apt-get purge -yq letsencrypt >/dev/null 2>&1'
  exec_cmd 'apt-get autoremove -yq >/dev/null 2>&1'
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
  exec_cmd 'rm apt-get purge -yq certbot >/dev/null 2>&1'

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
install_node()
{
  echo ""
  inf "Installing Node.js..."
  echo ""

  local install=0

  if command_exists node; then
    inf "node.js is already installed. Will attempt to upgrade..."
    exec_cmd 'apt-get install --only-upgrade -y nodejs >/dev/null'
    install=1
  fi

  # Only need to install docker ppa for new installs
  if [ $install -eq 0 ]; then
    exec_cmd 'apt-get install -y python-software-properties apt-transport-https ca-certificates curl software-properties-common >/dev/null'
    exec_nonprv_cmd "wget -O /tmp/node-install.sh https://deb.nodesource.com/setup_8.x"
    exec_nonprv_cmd "chmod +x /tmp/node-install.sh"
    exec_cmd "/tmp/node-install.sh"
    exec_cmd 'apt-get install -y nodejs >/dev/null'
    exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER/.config"
    exec_cmd "rm /tmp/node-install.sh"
  fi

  if command_exists yarn; then
    inf "yarn (nodejs package mgr) is already installed. Will attempt to upgrade..."
    exec_cmd 'npm upgrade --global yarn >/dev/null'
  else
    exec_cmd 'npm install -g yarn >/dev/null'
  fi
}


### serverless
#
###
install_serverless()
{
  echo ""
  inf "Installing serverless utilities..."
  echo ""

  if command_exists serverless; then
    echo "serverless client is already installed. Will attempt to upgrade..."
    exec_cmd 'yarn global upgrade serverless >/dev/null'
  else
    exec_cmd 'yarn global add serverless >/dev/null'
  fi

  if command_exists apex; then
    echo "apex client is already installed. Will attempt to upgrade..."
    exec_cmd 'apex upgrade >/dev/null'
  else
    rm -rf /tmp/apex-install.sh
    wget -O /tmp/apex-install.sh \
      https://raw.githubusercontent.com/apex/apex/master/install.sh
    chmod +x /tmp/apex-install.sh
    exec_cmd '/tmp/apex-install.sh'
  fi

  if [ "$DEFAULT_USER" == 'root' ]; then
    chown "$DEV_USER":"$DEV_USER" -R "/home/$DEV_USER/.config/yarn/global/"
    chown "$DEV_USER":"$DEV_USER" -R "/home/$DEV_USER/.cache"
  else
    sudo chown "$DEFAULT_USER":"$DEFAULT_USER" -R "/home/$DEFAULT_USER/.config/yarn/global/"
    sudo chown "$DEFAULT_USER":"$DEFAULT_USER" -R "/home/$DEFAULT_USER/.cache"
  fi

  if command_exists functions; then
    echo "google cloud functions emulator is already installed. Will attempt to upgrade..."
    exec_cmd 'npm update -g @google-cloud/functions-emulator >/dev/null'
  else
    exec_cmd 'npm install -g @google-cloud/functions-emulator >/dev/null'
  fi
}


### docker
# https://docs.docker.com/engine/installation/linux/ubuntu/
# http://www.bretfisher.com/install-docker-ppa-on-ubuntu-16-04/
# https://www.ubuntuupdates.org/ppa/docker_new
###
install_docker()
{
  echo ""
  inf "Installing Docker Community Edition..."
  echo ""

  inf "  removing any old Docker packages"
  exec_cmd 'apt-get remove docker docker-engine >/dev/null'

  local install=0
  local docker_ce_ver="$DOCKER_VER-ce"

  if command_exists docker; then
    if [ $(docker -v | awk -F '[ ,]+' '{ print $3 }') == "$docker_ce_ver" ]; then
      warn "  docker-ce is already installed...skipping installation"
      echo ""
      install=2
    else
      inf "  docker-ce is already installed. But versions don't match, so will attempt to upgrade..."
      echo ""
      install=1
    fi
  fi

  # Only need to install docker ppa for new installs
  if [ $install -eq 0 ]; then
    install_docker_deps
  fi

  # Either Docker isn't installed or installed version doesn't match desired
  # version
  if [ $install -le 1 ]; then
    # Note: You can run "sudo apt-cache madison docker-ce" to see what versions
    # are available
    local target_ver="$DOCKER_VER~ce-0~ubuntu-$(lsb_release -cs)"

    echo ""
    inf "  installing / upgrading docker-ce"
    echo ""

    exec_cmd 'apt-get -y update >/dev/null'
    exec_cmd "apt-get install -yq --allow-unauthenticated docker-ce=$target_ver"
  fi

  # Finish configuring for new installations...
  if [ $install -eq 0 ]; then
    echo ""
    # edit dockerd startup to enable namespaces and ensure overlay2
    # note namespace won't work in all scenerios, like --net=host,
    # but its tighter security so it's recommended to try using first
    # this now uses the daemon.json method rather that the old way of modifying systemd
    exec_cmd "printf '{ \"userns-remap\" : \"default\" , \"storage-driver\" : \"overlay2\" }' > /etc/docker/daemon.json"

    exec_cmd 'groupadd -f docker'
    inf "added docker group"
    echo ""

    echo "$DEV_USER" > /tmp/bootstrap_usermod_feh || exit 1
    exec_cmd 'usermod -aG docker $(cat /tmp/bootstrap_usermod_feh)'
    rm -f /tmp/bootstrap_usermod_feh || exit 1
    inf "  added $DEV_USER to group docker"
    echo ""

   ## Start Docker
   if command_exists systemctl; then
     exec_cmd 'systemctl daemon-reload'
     exec_cmd 'systemctl enable docker'
     if [ ! -f "/var/run/docker.pid" ]; then
       exec_cmd 'systemctl start docker'
     else
       inf "  Docker appears to already be running...will restart"
       echo ""
       exec_cmd 'systemctl restart docker'
     fi

    else
     inf "  no systemctl found...assuming this OS is not using systemd (yet)"
     echo ""

     if [ ! -f "/var/run/docker.pid" ]; then
       exec_cmd 'service docker start'
     else
       inf "  Docker appears to already be running"
       echo ""
     fi
    fi
  fi

  # User must log off for these changes to take effect
  LOGOFF_REQ=1
}


install_docker_deps()
{
  echo ""
  inf "  adding ppa key and other prerequisites"
  echo ""
  exec_cmd 'apt-get install -y apt-transport-https ca-certificates curl software-properties-common >/dev/null'
  exec_cmd 'apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D >/dev/null'
  exec_cmd 'apt-get -y update >/dev/null'

  exec_cmd 'apt-get install -y "linux-image-extra-$(uname -r)" >/dev/null'
  exec_cmd 'echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list'

  if [ "$DISTRO_VER" == "14.04" ]; then
    exec_cmd 'apt-get install -y "linux-image-extra-$(uname -r)" linux-image-extra-virtual >/dev/null'
  fi
}



### Install libvirt and qemu-kvm
# https://???
###
install_kvm()
{
  echo ""
  inf "Installing libvirt and qemu-kvm..."
  echo ""

  if ! command_exists kvm-ok; then
    exec_cmd 'apt-get install -yq cpu-checker'
  fi
  kvm-ok > /dev/null || error "kvm is not supported on this machine" && exit 1

  exec_cmd 'apt-get install -yq qemu-kvm libvirt-bin virtinst bridge-utils'

  # Add $DEV_USER to the libvirtd group (use libvirt group for rpm based
  # distros) so you don't need to sudo
  # Debian/Ubuntu (NOTE: For Ubuntu 17.04 change the group to `libvirt`)
  if [ "$DISTRO_VER" > "16.10" ]; then
    exec_cmd "usermod -a -G libvirt $DEV_USER"
  else
    exec_cmd "usermod -a -G libvirtd $DEV_USER"
  fi

  # Update your current session for the group change to take effect
  # Debian/Ubuntu (NOTE: For Ubuntu 17.04 change the group to `libvirt`)
  if [ "$DISTRO_VER" > "16.10" ]; then
    exec_cmd 'newgrp libvirt'
  else
    exec_cmd 'newgrp libvirtd'
  fi
}


### bosh dependencies
# https://bosh.io/docs/cli-env-deps.html
###
bosh_deps_install()
{
  echo ""
  inf "Installing ubuntu dependencies for bosh CLI..."
  echo ""

  exec_cmd 'apt-get install -yq zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev \
    libxml2-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3 >/dev/null 2>&1'
  exec_cmd 'apt-get -y update >/dev/null 2>&1'
}
