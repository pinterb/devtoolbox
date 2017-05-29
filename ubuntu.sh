#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

# http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/

base_setup()
{
  echo ""
  inf "Performing base setup..."
  echo ""

  if [ "$DEFAULT_USER" == 'root' ]; then
    su -c "mkdir -p /home/$DEV_USER/.bootstrap" "$DEV_USER"
    su -c "mkdir -p /home/$DEV_USER/bin" "$DEV_USER"
  else
    mkdir -p "/home/$DEV_USER/.bootstrap"
    mkdir -p "/home/$DEV_USER/bin"
  fi

  # in case a previous update failed
  if [ -d "/var/lib/dpkg/updates" ]; then
    $SH_C 'cd /var/lib/dpkg/updates; rm -f *'
  fi

  # for asciinema support
  $SH_C 'apt-add-repository -y ppa:zanchey/asciinema >/dev/null 2>&1'

  $SH_C 'apt-get install -yq git mercurial subversion letsencrypt wget curl jq unzip vim gnupg2 \
  build-essential autoconf automake libtool make g++ cmake make ssh gcc openssh-client python-dev python3-dev libssl-dev libffi-dev asciinema tree >/dev/null 2>&1'
  $SH_C 'apt-get -y update >/dev/null 2>&1'

  if ! command_exists pip; then
    echo ""
    inf "replacing python-pip with easy_install pip"
    echo ""
    $SH_C 'apt-get remove -y python-pip >/dev/null 2>&1'
    $SH_C 'apt-get install -y python-setuptools >/dev/null 2>&1'
    $SH_C 'easy_install pip >/dev/null 2>&1'
    echo ""
  fi

  $SH_C 'pip install --upgrade pyyaml >/dev/null 2>&1'
  $SH_C 'pip install --upgrade cookiecutter >/dev/null 2>&1'

  $SH_C 'apt-get -y autoremove >/dev/null 2>&1'
}


### node.js
# http://tecadmin.net/install-latest-nodejs-npm-on-ubuntu/#
###
install_node()
{
  echo ""
  inf "Installing Node.js..."
  echo ""

  $SH_C 'apt-get install -y python-software-properties >/dev/null'
  curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
  $SH_C 'apt-get install -y nodejs >/dev/null'

  if command_exists yarn; then
    echo "yarn (nodejs package mgr) is already installed. Will attempt to upgrade..."
    $SH_C 'npm upgrade --global yarn >/dev/null'
  else
    $SH_C 'npm install -g yarn >/dev/null'
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
    $SH_C 'yarn global upgrade serverless >/dev/null'
    ##$SH_C 'yarn global add serverless'
  else
    ##$SH_C 'yarn global upgrade serverless'
    $SH_C 'yarn global add serverless >/dev/null'
  fi

  if command_exists apex; then
    echo "apex client is already installed. Will attempt to upgrade..."
    $SH_C 'apex upgrade >/dev/null'
  else
    rm -rf /tmp/apex-install.sh
    wget -O /tmp/apex-install.sh \
      https://raw.githubusercontent.com/apex/apex/master/install.sh
    chmod +x /tmp/apex-install.sh
    $SH_C '/tmp/apex-install.sh'
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
    $SH_C 'npm update -g @google-cloud/functions-emulator >/dev/null'
  else
    $SH_C 'npm install -g @google-cloud/functions-emulator >/dev/null'
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

  inf "removing any old Docker packages"
  $SH_C 'apt-get remove docker docker-engine >/dev/null'
  echo ""

  local install=0
  local docker_ce_ver="$DOCKER_VER-ce"


  if command_exists docker; then
    if [ $(docker -v | awk -F '[ ,]+' '{ print $3 }') == "$docker_ce_ver" ]; then
      warn "docker-ce is already installed...skipping installation"
      echo ""
      install=1
    else
      inf "docker-ce is already installed. But versions don't match, so will attempt to upgrade..."
      echo ""
    fi
  fi

  # Either Docker isn't installed or installed version doesn't match desired
  # version
  if [ $install -eq 0 ]; then
    inf "adding ppa key and other prerequisites"
    echo ""
    $SH_C 'apt-get install -y apt-transport-https ca-certificates curl software-properties-common >/dev/null'
    $SH_C 'apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D >/dev/null'
    $SH_C 'apt-get -y update >/dev/null'

    $SH_C 'apt-get install -y "linux-image-extra-$(uname -r)" >/dev/null'
    $SH_C 'echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list'

    if [ "$DISTRO_VER" == "14.04" ]; then
      $SH_C 'apt-get install -y "linux-image-extra-$(uname -r)" linux-image-extra-virtual >/dev/null'
    fi

    # Note: You can run "sudo apt-cache madison docker-ce" to see what versions
    # are available
    local target_ver="$DOCKER_VER~ce-0~ubuntu-$(lsb_release -cs)"

    echo ""
    inf "installing / upgrading docker-ce"
    echo ""

    $SH_C 'apt-get -y update >/dev/null'
    $SH_C "apt-get install -yq docker-ce=$target_ver"
    echo ""

    # edit dockerd startup to enable namespaces and ensure overlay2
    # note namespace won't work in all scenerios, like --net=host,
    # but its tighter security so it's recommended to try using first
    # this now uses the daemon.json method rather that the old way of modifying systemd
    $SH_C "printf '{ \"userns-remap\" : \"default\" , \"storage-driver\" : \"overlay2\" }' > /etc/docker/daemon.json"
  fi

  $SH_C 'groupadd -f docker'
  inf "added docker group"
  echo ""

  echo "$DEV_USER" > /tmp/bootstrap_usermod_feh || exit 1
  $SH_C 'usermod -aG docker $(cat /tmp/bootstrap_usermod_feh)'
  rm -f /tmp/bootstrap_usermod_feh || exit 1
  inf "added $DEV_USER to group docker"
  echo ""

  ## Start Docker
  if command_exists systemctl; then
    $SH_C 'systemctl daemon-reload'
    $SH_C 'systemctl enable docker'
    if [ ! -f "/var/run/docker.pid" ]; then
      $SH_C 'systemctl start docker'
    else
      inf "Docker appears to already be running...will restart"
      echo ""
      $SH_C 'systemctl restart docker'
    fi

  else
    inf "no systemctl found...assuming this OS is not using systemd (yet)"
    echo ""

    if [ ! -f "/var/run/docker.pid" ]; then
      $SH_C 'service docker start'
    else
      inf "Docker appears to already be running"
      echo ""
    fi
  fi

  # User must log off for these changes to take effect
  LOGOFF_REQ=1
}
