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

  $SH_C 'apt-get install -yq software-properties-common git mercurial subversion wget curl jq unzip vim gnupg2 \
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

  if ! command_exists pip3; then
    echo ""
    inf "replacing python3-pip with easy_install pip3"
    echo ""
    $SH_C 'apt-get install -y python3-setuptools >/dev/null 2>&1'
    $SH_C 'easy_install3 pip >/dev/null 2>&1'
    echo ""
  fi

  $SH_C 'pip3 install --upgrade pyyaml >/dev/null 2>&1'
  $SH_C 'pip3 install --upgrade cookiecutter >/dev/null 2>&1'

  $SH_C 'apt-get -y autoremove >/dev/null 2>&1'
}


install_letsencrypt()
{
  echo ""
  inf "Installing Lets Encrypt package for Ubuntu..."
  echo ""

  $SH_C 'apt-get install -yq letsencrypt >/dev/null 2>&1'
  $SH_C 'apt-get -y update >/dev/null 2>&1'
}


### certbot
# https://certbot.eff.org/all-instructions/#ubuntu-16-04-xenial-none-of-the-above
###
install_certbot()
{
  echo ""
  inf "Installing certbot package for Ubuntu..."
  echo ""

  $SH_C 'apt-add-repository -y ppa:certbot/certbot >/dev/null 2>&1'
  $SH_C 'apt-get -y update >/dev/null 2>&1'
  $SH_C 'apt-get install -yq certbot >/dev/null 2>&1'

  echo ""
  inf "   installing certbot plugin for Gandi..."
  git clone https://github.com/Gandi/letsencrypt-gandi.git /tmp/letsencrypt-gandi
  if [ ! -d /tmp/letsencrypt-gandi ]; then
    error "   failed to git clone gandi plugin repository"
    exit 1
  else
    cd /tmp/letsencrypt-gandi
    $SH_C 'pip install -e . >/dev/null 2>&1'
    cd -
    $SH_C 'rm -rf /tmp/letsencrypt-gandi'
  fi

  echo ""
  inf "   installing certbot plugin for S3/CloudFront..."
  $SH_C 'pip install certbot-s3front >/dev/null 2>&1'

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

  inf "  removing any old Docker packages"
  $SH_C 'apt-get remove docker docker-engine >/dev/null'

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

    $SH_C 'apt-get -y update >/dev/null'
    $SH_C "apt-get install -yq docker-ce=$target_ver"
  fi

  # Finish configuring for new installations...
  if [ $install -eq 0 ]; then
    echo ""
    # edit dockerd startup to enable namespaces and ensure overlay2
    # note namespace won't work in all scenerios, like --net=host,
    # but its tighter security so it's recommended to try using first
    # this now uses the daemon.json method rather that the old way of modifying systemd
    $SH_C "printf '{ \"userns-remap\" : \"default\" , \"storage-driver\" : \"overlay2\" }' > /etc/docker/daemon.json"

    $SH_C 'groupadd -f docker'
    inf "added docker group"
    echo ""

    echo "$DEV_USER" > /tmp/bootstrap_usermod_feh || exit 1
    $SH_C 'usermod -aG docker $(cat /tmp/bootstrap_usermod_feh)'
    rm -f /tmp/bootstrap_usermod_feh || exit 1
    inf "  added $DEV_USER to group docker"
    echo ""

   ## Start Docker
   if command_exists systemctl; then
     $SH_C 'systemctl daemon-reload'
     $SH_C 'systemctl enable docker'
     if [ ! -f "/var/run/docker.pid" ]; then
       $SH_C 'systemctl start docker'
     else
       inf "  Docker appears to already be running...will restart"
       echo ""
       $SH_C 'systemctl restart docker'
     fi

    else
     inf "  no systemctl found...assuming this OS is not using systemd (yet)"
     echo ""

     if [ ! -f "/var/run/docker.pid" ]; then
       $SH_C 'service docker start'
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
  $SH_C 'apt-get install -y apt-transport-https ca-certificates curl software-properties-common >/dev/null'
  $SH_C 'apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D >/dev/null'
  $SH_C 'apt-get -y update >/dev/null'

  $SH_C 'apt-get install -y "linux-image-extra-$(uname -r)" >/dev/null'
  $SH_C 'echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >> /etc/apt/sources.list'

  if [ "$DISTRO_VER" == "14.04" ]; then
    $SH_C 'apt-get install -y "linux-image-extra-$(uname -r)" linux-image-extra-virtual >/dev/null'
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
    $SH_C 'apt-get install -yq cpu-checker'
  fi
  kvm-ok > /dev/null || error "kvm is not supported on this machine" && exit 1

  $SH_C 'apt-get install -yq qemu-kvm libvirt-bin virtinst bridge-utils'

  # Add $DEV_USER to the libvirtd group (use libvirt group for rpm based
  # distros) so you don't need to sudo
  # Debian/Ubuntu (NOTE: For Ubuntu 17.04 change the group to `libvirt`)
  if [ "$DISTRO_VER" > "16.10" ]; then
    $SH_C "usermod -a -G libvirt $DEV_USER"
  else
    $SH_C "usermod -a -G libvirtd $DEV_USER"
  fi

  # Update your current session for the group change to take effect
  # Debian/Ubuntu (NOTE: For Ubuntu 17.04 change the group to `libvirt`)
  if [ "$DISTRO_VER" > "16.10" ]; then
    $SH_C 'newgrp libvirt'
  else
    $SH_C 'newgrp libvirtd'
  fi
}


### bosh dependencies
# https://bosh.io/docs/cli-env-deps.html
###
bosh_deps_install()
{
  echo ""
  inf "Installing ubuntu dependencies for boch CLI..."
  echo ""

  $SH_C 'apt-get install -yq zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev \
    libxml2-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3 >/dev/null 2>&1'
  $SH_C 'apt-get -y update >/dev/null 2>&1'
}
