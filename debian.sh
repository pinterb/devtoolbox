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

  $SH_C 'apt-get -y update'
  $SH_C 'apt-get install -yq git mercurial subversion wget curl jq unzip vim gnupg2 \
  build-essential cmake make ssh gcc openssh-client python-dev python3-dev libssl-dev libffi-dev asciinema tree'

  if ! command_exists pip; then
    $SH_C 'apt-get remove -y python-pip'
    $SH_C 'apt-get install -y python-setuptools'
    $SH_C 'easy_install pip'
  fi

  $SH_C 'apt-get -y autoremove'
}


### docker
# https://docs.docker.com/engine/installation/linux/
###
install_docker()
{
  echo ""
  inf "Installing Docker..."
  echo ""

  if command_exists docker; then
    local version="$(docker -v | awk -F '[ ,]+' '{ print $3 }')"
    local MAJOR_W=1
    local MINOR_W=10
    semverParse $version
    warn "Docker $version is already installed...skipping installation"
  else
    $SH_C 'apt-get install -y apt-transport-https ca-certificates'
    $SH_C 'apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D'
    $SH_C 'apt-get -y update'

    if [ "$DISTRO_VER" == "8.5" ]; then
      echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list
    else
      echo "deb http://http.debian.net/debian wheezy-backports main" > /etc/apt/sources.list.d/backports.list
      echo "deb https://apt.dockerproject.org/repo debian-wheezy main" > /etc/apt/sources.list.d/docker.list
    fi

    $SH_C 'apt-get -y update'
    $SH_C 'apt-get install -yq docker-engine'
  fi

  $SH_C 'groupadd -f docker'
  inf "added docker group"

  echo "$DEV_USER" > /tmp/bootstrap_usermod_feh || exit 1
  $SH_C 'usermod -aG docker $(cat /tmp/bootstrap_usermod_feh)'
  rm -f /tmp/bootstrap_usermod_feh || exit 1
  inf "added $DEV_USER to group docker"

  ## Start Docker
  if command_exists systemctl; then
    $SH_C 'systemctl enable docker'
    if [ ! -f "/var/run/docker.pid" ]; then
      $SH_C 'systemctl start docker'
    else
      inf "Docker appears to already be running"
    fi
  else
    inf "no systemctl found...assuming this OS is not using systemd (yet)"
    if [ ! -f "/var/run/docker.pid" ]; then
      $SH_C 'service docker start'
    else
      inf "Docker appears to already be running"
    fi
  fi

  # User must log off for these changes to take effect
  LOGOFF_REQ=1
}

