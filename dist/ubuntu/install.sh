#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

# http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/

base_setup()
{
  echo ""
  hdr "Performing base setup..."
  echo ""

  # For new bootstrap, start by updating...
  if ! is_backed_up; then
    exec_cmd "apt-get -y update >/dev/null 2>&1"
    # ...and then backup
    # NOTE: base_backup should create .bootstrap directory
    base_backup
  fi

  if [ "$DEFAULT_USER" == 'root' ]; then
    su -c "mkdir -p /home/$DEV_USER/.bootstrap/profile.d" "$DEV_USER"
    su -c "mkdir -p /home/$DEV_USER/projects" "$DEV_USER"
  else
    mkdir -p "/home/$DEV_USER/.bootstrap/profile.d"
    mkdir -p "/home/$DEV_USER/projects"
  fi

  if ! is_installed basepkgs; then
    base_packages
  else
    inf "base packages already added"
  fi
}


base_backup()
{
  echo ""
  inf "performing base backup of packages, sources, keys, etc..."
  echo ""
  _backup "orig"
}


base_packages()
{
  echo ""
  inf "adding base packages, sources, utilities, etc..."
  echo ""

  if is_installed basepkgs; then
    error "base packages already installed"
    exit 1
  fi

  # in case a previous update failed
  if [ -d "/var/lib/dpkg/updates" ]; then
    exec_cmd 'rm -f /var/lib/dpkg/updates/*'
  fi

  local pkgs="software-properties-common jq unzip gnupg2 build-essential make autoconf automake"
  pkgs="$pkgs libtool g++ ctags cmake gcc openssh-client python-dev python3-dev libssl-dev libffi-dev"
  pkgs="$pkgs tree direnv"

  # ncurses is required for building kris-nova/kubicorn
  pkgs="$pkgs libncurses-dev"

  # libvirt is required for building docker/infrakit
  pkgs="$pkgs libvirt-dev"

  # direnv can be used for managing cloud credentials (e.g. AWS prod vs. stage)
  # http://direnv.net/
  pkgs="$pkgs direnv"

  # for asciinema support
  if ! command_exists asciinema; then
    exec_cmd 'apt-add-repository -y ppa:zanchey/asciinema >/dev/null 2>&1'
    exec_cmd 'apt-get -yq update >/dev/null 2>&1'
    pkgs="$pkgs asciinema"
  fi

  # for lsb_release support
  if ! command_exists lsb_release; then
    pkgs="$pkgs lsb-release"
  fi

  inf "installing base packages..."
  exec_cmd "apt-get install -yq --allow-unauthenticated $pkgs >/dev/null 2>&1"

  if ! command_exists pip; then
    echo ""
    inf "replacing python-pip with easy_install pip"
    echo ""
    exec_cmd 'apt-get remove -y python-pip >/dev/null 2>&1'
    exec_cmd 'apt-get install -y python-setuptools >/dev/null 2>&1'
    exec_cmd 'easy_install pip >/dev/null 2>&1'
    echo ""
  fi

  if ! command_exists pip3; then
    echo ""
    inf "replacing python3-pip with easy_install pip3"
    echo ""
    exec_cmd 'apt-get install -y python3-setuptools >/dev/null 2>&1'
    exec_cmd 'easy_install3 pip >/dev/null 2>&1'
    echo ""
  fi

  local pippkgs="pyyaml cookiecutter"
  exec_cmd "pip install --upgrade $pippkgs >/dev/null 2>&1"
  exec_cmd "pip3 install --upgrade $pippkgs >/dev/null 2>&1"

  exec_cmd 'apt-get -y autoremove >/dev/null 2>&1'

  mark_as_installed basepkgs
}


backup()
{
  if [[ -z $1 ]]; then
    error "backup requires a 'name' param"
    exit 1
  fi

  echo ""
  inf "performing base backup of packages, sources, keys, etc..."
  echo ""
  _backup $1
}


_backup()
{
  local bkup="${1:-orig}"
  if [ -d "/home/$DEV_USER/.bootstrap/backup/$bkup" ]; then
    bkup=$(date +"%Y%m%d%s")
  fi

  if [ "$DEFAULT_USER" == 'root' ]; then
    su -c "mkdir -p /home/$DEV_USER/.bootstrap/backup/$bkup" "$DEV_USER"
  else
    mkdir -p "/home/$DEV_USER/.bootstrap/backup/$bkup"
  fi

  exec_cmd "dpkg --get-selections > /home/$DEV_USER/.bootstrap/backup/$bkup/Package.list"
  exec_cmd "cp -R /etc/apt/sources.list* /home/$DEV_USER/.bootstrap/backup/$bkup/"
  exec_cmd "apt-key exportall > /home/$DEV_USER/.bootstrap/backup/$bkup/Repo.keys"

  if [ -f "/home/$DEV_USER/.profile" ]; then
    exec_cmd "cp /home/$DEV_USER/.profile /home/$DEV_USER/.bootstrap/backup/$bkup/dotprofile"
  fi

  if [ -f "/home/$DEV_USER/.bash_profile" ]; then
    exec_cmd "cp /home/$DEV_USER/.bash_profile /home/$DEV_USER/.bootstrap/backup/$bkup/dotbash_profile"
  fi

  if [ -f "/home/$DEV_USER/.bashrc" ]; then
    exec_cmd "cp /home/$DEV_USER/.bashrc /home/$DEV_USER/.bootstrap/backup/$bkup/dotbashrc"
  fi

  if [ -f "/home/$DEV_USER/.vimrc" ]; then
    exec_cmd "cp /home/$DEV_USER/.vimrc /home/$DEV_USER/.bootstrap/backup/$bkup/dotvimrc"
  fi

  if [ -f "/home/$DEV_USER/.gitconfig" ]; then
    exec_cmd "cp /home/$DEV_USER/.gitconfig /home/$DEV_USER/.bootstrap/backup/$bkup/dotgitconfig"
  fi

  if [ -d "/home/$DEV_USER/.vim" ]; then
    exec_cmd "cp -R /home/$DEV_USER/.vim /home/$DEV_USER/.bootstrap/backup/$bkup/dotvim"
  fi

  echo ""
}


install_letsencrypt()
{
  echo ""
  inf "installing Lets Encrypt package for Ubuntu..."
  echo ""

  if ! command_exists letsencrypt; then
    exec_cmd 'apt-get install -yq --allow-unauthenticated letsencrypt >/dev/null 2>&1'
    exec_cmd 'apt-get -y update >/dev/null 2>&1'
    mark_as_installed letsencrypt
  else
    exec_cmd 'apt-get install --only-upgrade -yq letsencrypt >/dev/null'
  fi

}


### certbot
# https://certbot.eff.org/all-instructions/#ubuntu-16-04-xenial-none-of-the-above
###
install_certbot()
{
  echo ""
  inf "installing certbot package for Ubuntu..."
  echo ""

  local install=0

  if command_exists certbot; then
    inf "cerbot is already installed. Will attempt to upgrade..."
    exec_cmd 'apt-get install --only-upgrade -yq certbot >/dev/null'
    install=1
  else
    exec_cmd 'apt-add-repository -y ppa:certbot/certbot >/dev/null 2>&1'
    exec_cmd 'apt-get -y update >/dev/null 2>&1'
    exec_cmd 'apt-get install -yq --allow-unauthenticated certbot >/dev/null 2>&1'
    mark_as_installed certbot
  fi

  echo ""
  inf "installing certbot plugin for Gandi..."
  git clone https://github.com/Gandi/letsencrypt-gandi.git /tmp/letsencrypt-gandi

  if [ ! -d /tmp/letsencrypt-gandi ]; then
    error "failed to git clone gandi plugin repository"
    exit 1
  else
    cd /tmp/letsencrypt-gandi
    exec_cmd 'pip install -e . >/dev/null 2>&1'
    cd -
    exec_cmd 'rm -rf /tmp/letsencrypt-gandi'
  fi

  echo ""
  inf "installing certbot plugin for S3/CloudFront..."
  exec_cmd 'pip install certbot-s3front >/dev/null 2>&1'

  echo ""
}


### node.js
# http://tecadmin.net/install-latest-nodejs-npm-on-ubuntu/#
###
install_node()
{
  echo ""
  hdr "Installing Node.js..."
  echo ""

  local install=0

  if command_exists node; then
    inf "node.js is already installed. Will attempt to upgrade..."
    exec_cmd 'apt-get install --only-upgrade -y nodejs >/dev/null'
    mark_as_installed node
    install=1
  fi

  if [ "$DEFAULT_USER" == 'root' ]; then
    su -c "mkdir -p /home/$DEV_USER/.config" "$DEV_USER"
  else
    mkdir -p "/home/$DEV_USER/.config"
  fi

  # Only need to install packages, download files, etc. for new installs
  if [ $install -eq 0 ]; then
    exec_cmd 'apt-get install -y python-software-properties apt-transport-https ca-certificates curl software-properties-common >/dev/null'
    exec_nonprv_cmd "wget -O /tmp/node-install.sh https://deb.nodesource.com/setup_8.x"
    exec_nonprv_cmd "chmod +x /tmp/node-install.sh"
    exec_cmd "/tmp/node-install.sh"
    exec_cmd 'apt-get install -y nodejs >/dev/null'
    exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER/.config"
    exec_cmd "rm /tmp/node-install.sh"
    mark_as_installed node
  fi

  if command_exists yarn; then
    inf "yarn (nodejs package mgr) is already installed. Will attempt to upgrade..."
    exec_cmd 'npm upgrade --global yarn >/dev/null'
  else
    exec_cmd 'npm install -g yarn >/dev/null'
  fi

  # A hack for now, install 'codename'...
  #  codename can be used to come up with random github repository names
  exec_cmd 'npm install --global intel-codenames-picker >/dev/null'
}


### Azure cli
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
###
install_azure()
{
  echo ""
  hdr "Installing Azure cli..."
  echo ""

  local install=0

  if command_exists az; then
    if [ $(az --version | awk '{ print $2; exit }') == "($AZURE_VER)" ]; then
      warn "azure cli is already installed"
      install=2
    else
      inf "azure cli is already installed...but versions don't match"
      install=1
      exec_cmd 'apt-get -y update >/dev/null 2>&1'
      exec_cmd 'apt-get install -yq --allow-unauthenticated azure-cli >/dev/null 2>&1'
      mark_as_installed azurecli
    fi
  fi

  if [ $install -eq 0 ]; then
    #exec_cmd 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list'
    exec_cmd 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" > /etc/apt/sources.list.d/azure-cli.list'
    exec_cmd 'apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893'
    exec_cmd 'apt-get -y update >/dev/null 2>&1'
    exec_cmd 'apt-get install -yq --allow-unauthenticated azure-cli >/dev/null 2>&1'
    mark_as_installed azurecli
  fi
}


### serverless
#
###
install_serverless()
{
  echo ""
  hdr "Installing serverless utilities..."
  echo ""

  if ! command_exists node; then
    error "node is required to install some of the serverless utilities"
    error "...install node and then re-try."
    exit 1
  fi

  if ! command_exists yarn; then
    error "yarn is required to install some of the serverless utilities"
    error "...install node and then re-try."
    exit 1
  fi

  if command_exists serverless; then
    inf "serverless client is already installed. Will attempt to upgrade..."
    exec_cmd 'yarn global upgrade serverless >/dev/null'
  else
    exec_cmd 'yarn global add serverless >/dev/null'
  fi

  if command_exists apex; then
    inf "apex client is already installed. Will attempt to upgrade..."
    exec_cmd 'apex upgrade >/dev/null'
  else
    rm -rf /tmp/apex-install.sh
    wget -O /tmp/apex-install.sh \
      https://raw.githubusercontent.com/apex/apex/master/install.sh
    chmod +x /tmp/apex-install.sh
    exec_cmd '/tmp/apex-install.sh'
  fi

  if command_exists up; then
    inf "up client is already installed. Will attempt to upgrade..."
    exec_cmd 'up upgrade >/dev/null'
  else
    rm -rf /tmp/up-install.sh
    wget -O /tmp/up-install.sh \
      https://raw.githubusercontent.com/apex/up/master/install.sh
    chmod +x /tmp/up-install.sh
    exec_cmd '/tmp/up-install.sh'
  fi

  if [ "$DEFAULT_USER" == 'root' ]; then
    if [ -d "/home/$DEV_USER/.config" ]; then
      chown "$DEV_USER":"$DEV_USER" -R "/home/$DEV_USER/.config"
    fi
    if [ -d "/home/$DEV_USER/.cache" ]; then
      chown "$DEV_USER":"$DEV_USER" -R "/home/$DEV_USER/.cache"
    fi
  else
    if [ -d "/home/$DEV_USER/.config" ]; then
      sudo chown "$DEFAULT_USER":"$DEFAULT_USER" -R "/home/$DEFAULT_USER/.config"
    fi
    if [ -d "/home/$DEV_USER/.cache" ]; then
      sudo chown "$DEFAULT_USER":"$DEFAULT_USER" -R "/home/$DEFAULT_USER/.cache"
    fi
  fi

  if command_exists functions; then
    inf "google cloud functions emulator is already installed. Will attempt to upgrade..."
    exec_cmd 'npm update -g @google-cloud/functions-emulator >/dev/null'
  else
    exec_cmd 'npm install -g @google-cloud/functions-emulator >/dev/null'
  fi

  mark_as_installed serverless
}


### docker
# https://docs.docker.com/engine/installation/linux/ubuntu/
# http://www.bretfisher.com/install-docker-ppa-on-ubuntu-16-04/
# https://www.ubuntuupdates.org/ppa/docker_new
###
install_docker()
{
  echo ""
  hdr "Installing Docker Community Edition..."
  echo ""

  if microsoft_wsl; then
    warn "This appears to be a Windows WSL distribution of Ubuntu. "
    warn "Will attempt to install Docker without enabling & starting the Docker service."
    warn "  And instead, the DOCKER_HOST environment variable will point to native Windows Docker."
  fi

  inf "removing any old Docker packages"
  exec_cmd 'apt-get remove docker docker-engine docker.io >/dev/null'

  local install=0
  local docker_ce_ver="$DOCKER_VER-ce"

  if command_exists docker; then
    if [ $(docker -v | awk -F '[ ,]+' '{ print $3 }') == "$docker_ce_ver" ]; then
      warn "docker-ce is already installed...skipping installation"
      echo ""
      install=2
    else
      inf "docker-ce is already installed. But versions don't match, so will attempt to upgrade..."
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
    local target_ver="$DOCKER_VER~ce-0~ubuntu-$(lsb_release -cs)" #NOTE: This was valid prior to 17.0.6
    #local target_ver="$DOCKER_VER~ce-0~ubuntu"

    echo ""
    inf "installing / upgrading docker-ce"
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
    if ! microsoft_wsl; then
      exec_cmd "printf '{ \"storage-driver\" : \"overlay2\" }' > /etc/docker/daemon.json"
    fi

    exec_cmd 'groupadd -f docker'
    inf "added docker group"
    echo ""

    echo "$DEV_USER" > /tmp/bootstrap_usermod_feh || exit 1
    exec_cmd 'usermod -aG docker $(cat /tmp/bootstrap_usermod_feh)'
    rm -f /tmp/bootstrap_usermod_feh || exit 1
    inf "added $DEV_USER to group docker"
    echo ""

    ## Start Docker
    if microsoft_wsl; then

      inf "Since this appears to be a Windows WSL distribution of Ubuntu... "
      inf "   updating ~/.bootstrap/profile.d/ with DOCKER_HOST"
      echo "# The following DOCKER_HOST was automatically added by $PROGDIR/$PROGNAME" > "/home/$DEV_USER/.bootstrap/profile.d/docker.sh"

      echo "# This configuration is based on: https://taoofmac.com/space/blog/2017/05/07/1920 " >> "/home/$DEV_USER/.bootstrap/profile.d/docker.sh"
      echo "export DOCKER_HOST='localhost:2375'" >> "/home/$DEV_USER/.bootstrap/profile.d/docker.sh"

      #echo "# This configuration is based on: https://blog.jayway.com/2017/04/19/running-docker-on-bash-on-windows/ " >> "/home/$DEV_USER/.bootstrap/profile.d/docker.sh"
      #echo "export DOCKER_HOST='tcp://0.0.0.0:2375'" >> "/home/$DEV_USER/.bootstrap/profile.d/docker.sh"

    elif command_exists systemctl; then

      exec_cmd 'systemctl daemon-reload'
      exec_cmd 'systemctl enable docker'
      if [ ! -f "/var/run/docker.pid" ]; then
        exec_cmd 'systemctl start docker'
      else
        inf "Docker appears to already be running...will restart"
        echo ""
        exec_cmd 'systemctl restart docker'
      fi

    else
      inf "no systemctl found...assuming this OS is not using systemd (yet)"
      echo ""

      if [ ! -f "/var/run/docker.pid" ]; then
        exec_cmd 'service docker start'
      else
        inf "Docker appears to already be running"
        echo ""
      fi
    fi # ms wsl, or systemctl

    mark_as_installed docker
  fi

  if [ $install -eq 0 ]; then
    # User must log off for these changes to take effect
    LOGOFF_REQ=1
  fi
}


install_docker_deps()
{
  echo ""
  inf "adding docker ppa key and other prerequisites"
  echo ""
  exec_cmd 'apt-get install -y apt-transport-https ca-certificates curl software-properties-common >/dev/null'
  exec_cmd 'apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D >/dev/null'
  exec_cmd 'apt-get -y update >/dev/null'

  if microsoft_wsl; then
    exec_cmd 'echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable" > /etc/apt/sources.list.d/docker.list'
  else
    exec_cmd 'apt-get install -y "linux-image-extra-$(uname -r)" >/dev/null'
    exec_cmd 'echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list'
  fi

  if [ "$DISTRO_VER" == "14.04" ]; then
    exec_cmd 'apt-get install -y "linux-image-extra-$(uname -r)" linux-image-extra-virtual >/dev/null'
  fi
}


### inspec
# https://www.inspec.io/downloads/
###
install_inspec()
{
  echo ""
  hdr "Installing InSpec..."
  echo ""

  local install=0
  local inspec_ver="$INSPEC_VER"

  if command_exists inspec; then
    if [ $(inspec version | awk '{ print $1; exit }') == "$inspec_ver" ]; then
      warn "InSpec is already installed...skipping installation"
      echo ""
      install=2
    else
      inf "InSpec is already installed. But versions don't match, so will attempt to upgrade..."
      echo ""
      install=1
    fi
  fi

  # Only need to install inspec ppa for new installs
  if [ $install -eq 0 ]; then
    install_inspec_deps
  fi

  # Either Inspec isn't installed or installed version doesn't match desired
  # version
  if [ $install -le 1 ]; then
    # Note: You can run "sudo apt-cache madison inspec" to see what versions
    # are available
    local target_ver="$INSPEC_VER-1"

    echo ""
    inf "installing / upgrading InSpec"
    echo ""

    exec_cmd 'apt-get -y update >/dev/null'
    exec_cmd "apt-get install -yq --allow-unauthenticated inspec=$target_ver"

    mark_as_installed inspec
  fi

}


install_inspec_deps()
{
  echo ""
  inf "adding inspec ppa key and other prerequisites"
  echo ""
  exec_cmd 'apt-get install -y apt-transport-https >/dev/null'
  exec_cmd 'wget -qO - https://packages.chef.io/chef.asc > /tmp/inspec-key'
  exec_cmd 'apt-key add /tmp/inspec-key'
  exec_cmd 'rm /tmp/inspec-key'

  if microsoft_wsl; then
    exec_cmd 'echo "deb https://packages.chef.io/repos/apt/stable xenial main" > /etc/apt/sources.list.d/chef-stable.list'
  else
    exec_cmd 'echo "deb https://packages.chef.io/repos/apt/stable $(lsb_release -cs) main" > /etc/apt/sources.list.d/chef-stable.list'
  fi

  exec_cmd 'apt-get -y update >/dev/null'
}


### Install the XFCE window manager
# https://xfce.org/
#
# NOTE: Currently, this is only intended for Ubuntu running from Windows' WSL (aka Bash on Windows)
###
install_xfce()
{
  echo ""
  hdr "Installing XFCE window manager..."
  echo ""

  if ! microsoft_wsl; then
    error "this doesn't appear to be a Windows WSL distribution of Ubuntu"
    exit 1
  fi

  exec_cmd 'apt-get install -y realpath xfce4 >/dev/null'
  mark_as_installed xfce
}



### Install libvirt and qemu-kvm
# https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#kvm2-driver)
###
install_kvm()
{
  echo ""
  inf "Installing libvirt and qemu-kvm..."
  echo ""

  if ! command_exists kvm-ok; then
    exec_cmd 'apt-get install -yq cpu-checker'
  fi
  kvm-ok > /dev/null
  if [ $? -eq 0 ]; then
    inf "Okay...I think we can install kvm"
  else
    error "kvm is not supported on this machine"
    exit 1
  fi

  inf "what?"
  exec_cmd 'apt-get install -yq qemu-kvm libvirt-bin'

  # Add $DEV_USER to the libvirtd group (use libvirt group for rpm based
  # distros) so you don't need to sudo
  # Debian/Ubuntu (NOTE: For Ubuntu 17.04 change the group to `libvirt`)
  inf "$DISTRO_VER"
  if [[ "$DISTRO_VER" > "16.10" ]]; then
    inf "bleh"
    exec_cmd "usermod -a -G libvirt $DEV_USER"
  else
    exec_cmd "usermod -a -G libvirtd $DEV_USER"
  fi

  # Update your current session for the group change to take effect
  # Debian/Ubuntu (NOTE: For Ubuntu 17.04 change the group to `libvirt`)
  if [[ "$DISTRO_VER" > "16.10" ]]; then
    exec_cmd 'newgrp libvirt'
  else
    exec_cmd 'newgrp libvirtd'
  fi

  # download and install the kvm docker machine driver
  curl -Lo /tmp/docker-machine-driver-kvm2 https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-kvm2 && \
    chmod +x /tmp/docker-machine-driver-kvm2 && \
    exec_cmd "mv /tmp/docker-machine-driver-kvm2 /usr/bin/"
}


### bosh dependencies
# https://bosh.io/docs/cli-env-deps.html
###
bosh_deps_install()
{
  echo ""
  hdr "Installing ubuntu dependencies for bosh CLI..."
  echo ""

  exec_cmd 'apt-get install -yq zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev \
    libxml2-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3 >/dev/null 2>&1'
  exec_cmd 'apt-get -y update >/dev/null 2>&1'
}


###
# https://code.visualstudio.com/docs/setup/linux
###
install_vscode()
{
  echo ""
  hdr "Installing Visual Studio Code IDE..."
  echo ""

  if command_exists code; then
    error "Visual Studio Code appears to be installed."
    error "...if you're looking to upgrade, you should be able to that from the Visual Studio Code GUI."
    exit 1
  fi

  curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
  exec_cmd "mv /tmp/microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg"
  exec_cmd 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
  exec_cmd "apt-get -y update >/dev/null 2>&1"
  exec_cmd "apt-get install -yq --allow-unauthenticated code >/dev/null 2>&1"

  mark_as_installed vscode
}


###
# https://keybase.io/docs/the_app/install_linux
###
install_keybase()
{
  echo ""
  hdr "Installing keybase..."
  echo ""

  local install=0

  if command_exists run_keybase; then
    warn "Keybase appears to be installed.  Will attempt a package upgrade..."
    exec_cmd "apt-get install --only-upgrade keybase"
    exec_nonprv_cmd "run_keybase"
    install=1
  fi

  if [ $install -eq 0 ]; then
    exec_cmd "apt-get install -yq --allow-unauthenticated libappindicator1 libgconf-2-4 >/dev/null 2>&1"

    exec_cmd "rm -rf /tmp/keybase_amd64.deb"
    exec_nonprv_cmd "wget -O /tmp/keybase_amd64.deb https://prerelease.keybase.io/keybase_amd64.deb"
    exec_cmd "dpkg -i /tmp/keybase_amd64.deb"
    exec_cmd "apt-get install -f"
    exec_nonprv_cmd "run_keybase"
  fi

  mark_as_installed keybase
}


### Bazel
# https://docs.bazel.build/versions/master/install-ubuntu.html#install-on-ubuntu
###
install_bazel()
{
  echo ""
  hdr "Installing Bazel..."
  echo ""

  local install=0

  if command_exists bazel; then
    if [ $(bazel version | awk '{ print $3; exit }') == "$BAZEL_VER" ]; then
      warn "bazel is already installed"
      install=2
    else
      inf "bazel is already installed...but versions don't match"
      install=1
      exec_cmd 'apt-get upgrade -yq bazel >/dev/null 2>&1'
      mark_as_installed bazel
    fi
  fi

  # Only need to install java & bazel sources for new installs
  if [ $install -eq 0 ]; then
    install_bazel_deps
  fi

  # Bazel isn't installed
  if [ $install -le 1 ]; then
    exec_cmd 'apt-get install -yq --allow-unauthenticated bazel >/dev/null 2>&1'
    mark_as_installed bazel
  fi
}


install_bazel_deps()
{
  echo ""
  inf "adding bazel prerequisites"
  echo ""

  if [ "$DISTRO_VER" == "14.04" ]; then
    exec_cmd 'add-apt-repository -yq ppa:webupd8team/java'
    exec_cmd 'apt-get -y update >/dev/null 2>&1'
    exec_cmd 'apt-get install -yq --allow-unauthenticated oracle-java8-installer >/dev/null 2>&1'
  else
    exec_cmd 'apt-get install -y openjdk-8-jdk >/dev/null'
  fi

  exec_cmd 'echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" > /etc/apt/sources.list.d/bazel.list'

  exec_cmd 'wget -qO - https://bazel.build/bazel-release.pub.gpg > /tmp/bazel-key'
  exec_cmd 'apt-key add /tmp/bazel-key'
  exec_cmd 'rm /tmp/bazel-key'
  exec_cmd 'apt-get -y update >/dev/null 2>&1'

}


### Ballerina
# https://ballerina.io/downloads/
###
install_ballerina()
{
  echo ""
  hdr "Installing Ballerina..."
  echo ""

  local install=0

  if command_exists ballerina; then
    if [ $(ballerina version | awk '{ print $2; exit }') == "$BALLERINA_VER" ]; then
      warn "ballerina is already installed"
      install=2
    else
      inf "ballerina is already installed...but versions don't match"
      install=1
      exec_cmd 'apt-get upgrade -yq ballerina >/dev/null 2>&1'
      mark_as_installed ballerina
    fi
  fi

  # Only need to install ballerina sources for new installs
  if [ $install -eq 0 ]; then
    install_ballerina_deps
  fi

  # Ballerina isn't installed
  if [ $install -le 1 ]; then
    exec_cmd 'apt-get install -yq --allow-unauthenticated ballerina >/dev/null 2>&1'
    mark_as_installed ballerina
  fi
}


install_ballerina_deps()
{
  echo ""
  inf "adding ballerina prerequisites"
  echo ""

  exec_cmd 'apt-get -y update >/dev/null 2>&1'

  exec_cmd "rm -rf /tmp/ballerina_amd64.deb"
  exec_nonprv_cmd "wget -O /tmp/ballerina_amd64.deb https://product-dist.ballerina.io/downloads/${BALLERINA_VER}/ballerina-platform-linux-installer-x64-${BALLERINA_VER}.deb"
  exec_cmd "dpkg -i /tmp/ballerina_amd64.deb"
  exec_cmd "apt-get install -f"
}

