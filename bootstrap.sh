#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

# http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"
readonly ARGS="$@"
readonly TODAY=$(date +%Y%m%d%H%M%S)

# pull in utils
source "${PROGDIR}/utils.sh"

## pull in distro-specific install / uninstall functions
#source "${PROGDIR}/dist/$(echo $DISTRO_ID | tr '[:upper:]' '[:lower:]')/install.sh"
#source "${PROGDIR}/dist/$(echo $DISTRO_ID | tr '[:upper:]' '[:lower:]')/uninstall.sh"

# cli arguments
DEV_USER=
UNINSTALL=
INSTALL_BASE=
INSTALL_DOTFILES=
INSTALL_TLS=
INSTALL_ANSIBLE=
INSTALL_AWS=
INSTALL_KOPS=
INSTALL_KUBE_AWS=
INSTALL_DOCKER=
INSTALL_GOLANG=
INSTALL_GCLOUD=
INSTALL_TERRAFORM=
INSTALL_VIM=
INSTALL_PROTO_BUF=
INSTALL_NODE=
INSTALL_SERVERLESS=
INSTALL_HYPER=
INSTALL_DO=
INSTALL_HABITAT=
INSTALL_AZURE=
INSTALL_NGROK=
INSTALL_MINIKUBE=
INSTALL_KUBECTL=
INSTALL_HELM=
INSTALL_DRAFT=
INSTALL_BOSH=

# misc. flags
SHOULD_WARM=0
LOGOFF_REQ=0

# list of packages with "uninstall" support
UNINST_SUPPORT="azure, aws, gcloud, digitalocean, terraform, node.js, ngrok, tls, and golang"

# based on user, determine how commands will be executed
# ### DEPRECATE THIS???
#SH_C='bash -c'
#if [ "$DEFAULT_USER" != 'root' ]; then
#  if command_exists sudo; then
#    SH_C='sudo -E bash -c'
#  elif command_exists su; then
#    SH_C='su -c'
#  else
#    error "This installer needs the ability to run commands as root."
#    error "We are unable to find either "sudo" or "su" available to make this happen."
#    exit 1
#  fi
#fi


bail() {
  error "problems executing command, exiting"
  exit 1
}


# execute a bash with sudo or su
# ...without failure
exec_cmd_nobail() {
  cmd_inf "$1"

  if [ "$DEFAULT_USER" != 'root' ]; then
    if command_exists sudo; then
      sudo -E bash -c "$1"
    elif command_exists su; then
      su -c "$1"
    else
      error "This installer needs the ability to run commands as root."
      error "We are unable to find either "sudo" or "su" available to make this happen."
      exit 1
    fi
  else
    bash -c "$1"
  fi
}


# execute a bash with sudo or su
exec_cmd() {
  exec_cmd_nobail "$1" || bail
}


# execute as a non-privileged user
# ...without failure
exec_nonprv_cmd_nobail() {
  cmd_inf "$1"
  bash -c "$1"
}


# execute as a non-privileged user
exec_nonprv_cmd() {
  exec_nonprv_cmd_nobail "$1" || bail
}


usage() {
  cat <<- EOF
  usage: $PROGNAME options

  $PROGNAME installs various Linux packages and untilites commonly used for development and devlops by a new, non-privileged user.
  Currently, only Ubuntu is supported.

  OPTIONS:
    --user <userid>        non-privileged user account to be bootstrapped (NOTE: invalid option when running as non-privileged user)
    --base-setup           base packages (e.g. jq, tree, python3, unzip, build-essential)
    --dotfiles             opinionated dotfiles

    --aws                  aws cli
    --azure                azure cli
    --bosh                 bosh cli
    --digitalocean         digitalocean cli
    --gcloud               gcloud cli
    --hyper                hyper.sh (Hyper.sh is a hypervisor-agnostic Docker runtime)

    --ansible              ansible
    --docker               docker
    --terraform            terraform

    --golang               golang (incl. third-party utilities)
    --habitat              habitat.sh (Habitat enables you to build and run your applications in a Cloud Native manner.)
    --node                 node.js
    --proto-buf            protocol buffers (i.e. protoc)
    --serverless           various serverless utilities (e.g. serverless, apex, sparta)

    --minikube             opinionated local development workflow for applications deployed to Kubernetes (github.com/Azure/draft)
    --kubectl              kubectl
    --helm                 helm
    --draft                opinionated local development workflow for applications deployed to Kubernetes (github.com/Azure/draft)
    --kops                 kops (a kubernetes provisioning tool)
    --kube-aws             kube-aws (a kubernetes provisioning tool)

    --ngrok                create secure tunnels to localhost (ngrok.com)
    --tls-utils            utilities for managing TLS certificates (e.g. letsencrypt, cfssl)
    --vim                  vim-plug & choice plugins (e.g. vim-go)

    --uninstall            uninstall specified package(s) or utilities (incl. $UNINST_SUPPORT)

    -h --help              show this help


  Examples:
    $PROGNAME --user pinterb --golang
EOF
}

###
# http://mywiki.wooledge.org/ComplexOptionParsing
###
cmdline() {
  i=$(($# + 1)) # index of the first non-existing argument
  declare -A longoptspec
  # Use associative array to declare how many arguments a long option
  # expects. In this case we declare that loglevel expects/has one
  # argument and range has two. Long options that aren't listed in this
  # way will have zero arguments by default.
  longoptspec=( [user]=1 )
  optspec=":h-:"
  while getopts "$optspec" opt; do
  while true; do
    case "${opt}" in
      -) #OPTARG is name-of-long-option or name-of-long-option=value
        if [[ ${OPTARG} =~ .*=.* ]] # with this --key=value format only one argument is possible
        then
          opt=${OPTARG/=*/}
          ((${#opt} <= 1)) && {
            error "Syntax error: Invalid long option '$opt'" >&2
            exit 2
          }
          if (($((longoptspec[$opt])) != 1))
          then
            error "Syntax error: Option '$opt' does not support this syntax." >&2
            exit 2
          fi
          OPTARG=${OPTARG#*=}
        else #with this --key value1 value2 format multiple arguments are possible
          opt="$OPTARG"
          ((${#opt} <= 1)) && {
            error "Syntax error: Invalid long option '$opt'" >&2
            exit 2
          }
          OPTARG=(${@:OPTIND:$((longoptspec[$opt]))})
          ((OPTIND+=longoptspec[$opt]))
          #echo $OPTIND
          ((OPTIND > i)) && {
          error "Syntax error: Not all required arguments for option '$opt' are given." >&2
          exit 3
          }
        fi

        continue #now that opt/OPTARG are set we can process them as
        # if getopts would've given us long options
        ;;
      user)
        DEV_USER=$OPTARG
        ;;
      ansible)
        readonly INSTALL_ANSIBLE=1
        ;;
      azure)
        readonly INSTALL_AZURE=1
        ;;
      base-setup)
        readonly INSTALL_BASE=1
        ;;
      bosh)
        readonly INSTALL_BOSH=1
        ;;
      docker)
        readonly INSTALL_DOCKER=1
        ;;
      dotfiles)
        readonly INSTALL_DOTFILES=1
        ;;
      draft)
        readonly INSTALL_DRAFT=1
        ;;
      golang)
        readonly INSTALL_GOLANG=1
        ;;
      digitalocean)
        readonly INSTALL_DO=1
        ;;
      aws)
        readonly INSTALL_AWS=1
        ;;
      gcloud)
        readonly INSTALL_GCLOUD=1
        ;;
      habitat)
        readonly INSTALL_HABITAT=1
        ;;
      helm)
        readonly INSTALL_HELM=1
        ;;
      hyper)
        readonly INSTALL_HYPER=1
        ;;
      kops)
        readonly INSTALL_KOPS=1
        ;;
      kubectl)
        readonly INSTALL_KUBECTL=1
        ;;
      kube-aws)
        readonly INSTALL_KUBE_AWS=1
        ;;
      minikube)
        readonly INSTALL_MINIKUBE=1
        ;;
      ngrok)
        readonly INSTALL_NGROK=1
        ;;
      node)
        readonly INSTALL_NODE=1
        ;;
      proto-buf)
        readonly INSTALL_PROTO_BUF=1
        ;;
      serverless)
        readonly INSTALL_SERVERLESS=1
        ;;
      terraform)
        readonly INSTALL_TERRAFORM=1
        ;;
      tls-utils)
        readonly INSTALL_TLS=1
        ;;
      vim)
        readonly INSTALL_VIM=1
        ;;
      uninstall)
        readonly UNINSTALL=1
        ;;
      h|help)
        usage
        exit 0
        ;;
      ?)
        error "Syntax error: Unknown short option '$OPTARG'" >&2
        exit 1
        ;;
      *)
        error "Syntax error: Unknown long option '$opt'" >&2
        exit 2
        ;;
    esac
    break; done
  done

}


distro_check()
{
  case "$DISTRO_ID" in
    Ubuntu)
      hdr "Configuring $DISTRO_ID $DISTRO_VER..."
      echo ""
      sleep 4
    ;;

    Debian)
      warn "Configuring $DISTRO_ID $DISTRO_VER..."
      warn "Support for this distro is spotty.  Your mileage will vary."
      warn ""
      warn "You may press Ctrl+C now to abort this script."
      sleep 10
    ;;

    RHEL)
      error "Configuring $DISTRO_ID $DISTRO_VER..."
      error "Unfortunately, this is an unsupported distro"
      error ""
      sleep 4
      exit 1
    ;;

    *)
      error "Configuring $DISTRO_ID $DISTRO_VER..."
      error "Unfortunately, this is an unsupported distro"
      error ""
      sleep 4
      exit 1
    ;;

  esac

  # pull in distro-specific install / uninstall functions
  source "${PROGDIR}/dist/$(echo $DISTRO_ID | tr '[:upper:]' '[:lower:]')/install.sh"
  source "${PROGDIR}/dist/$(echo $DISTRO_ID | tr '[:upper:]' '[:lower:]')/uninstall.sh"

}


valid_args()
{
  if [ "$DEFAULT_USER" != 'root' ]; then
    if [[ -z "$DEV_USER" ]]; then
      warn "Defaulting non-privileged user to $DEFAULT_USER"
      DEV_USER=$DEFAULT_USER
    elif [ "$DEFAULT_USER" != "$DEV_USER" ]; then
      error "When executing as a non-privileged user, --user option is not permitted"
      echo ""
      usage
      exit 1
    fi
  elif [[ -z "$DEV_USER" ]]; then
    error "a non-privileged user is required"
    echo  ""
    usage
    exit 1
  fi
}


# Make sure we have all the right stuff
prerequisites() {
  local git_cmd=$(which git)

  if [ -z "$git_cmd" ]; then
    error "git does not appear to be installed. Please install and re-run this script."
    exit 1
  fi

  # for now, let's assume someone else has already created our non-privileged user.
  ret=false
  getent passwd "$DEV_USER" >/dev/null 2>&1 && ret=true

  if ! $ret; then
    error "$DEV_USER user does not exist"
  fi

  if [ ! -d "/home/$DEV_USER" ]; then
    error "By convention, expecting /home/$DEV_USER to exist. Please create a user with /home directory."
  fi
}


###
# baseline packages and files
###
install_base()
{
  if function_exists base_setup; then
    base_setup
  else
    error "baseline install function doesn't exist."
    exit 1
  fi

  binfiles
}


binfiles()
{
  echo ""
  inf "copying binfiles..."

#  if [ "$DEFAULT_USER" == 'root' ]; then
#    su -c "mkdir -p /home/$DEV_USER/bin" "$DEV_USER"
#    su -c "cp -R $PROGDIR/binfiles/. /home/$DEV_USER/bin" "$DEV_USER"
#  else
#    exec_nonprv_cmd "mkdir -p /home/$DEV_USER/bin"
#    exec_nonprv_cmd "cp -R $PROGDIR/binfiles/. /home/$DEV_USER/bin"
#  fi

  exec_cmd "mkdir -p /home/$DEV_USER/bin"
  exec_cmd "cp -R $PROGDIR/binfiles/. /home/$DEV_USER/bin"
  exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER/bin"

  mark_as_installed binfiles

}


###
# install opinionated dot files
###
install_dotfiles()
{
  if function_exists dotfiles; then
    dotfiles
  else
    error "dot files install function doesn't exist."
    exit 1
  fi
}


dotfiles()
{
  echo ""
  hdr "Copying dotfiles..."
  echo ""

  # handle .bashrc
  if [ -f "/home/$DEV_USER/.bashrc" ]; then
    if [ ! -f "/home/$DEV_USER/.bashrc-orig" ]; then
      inf "Backing up .bashrc file"
      exec_nonprv_cmd "cp /home/$DEV_USER/.bashrc /home/$DEV_USER/.bashrc-orig"

      if [ -f "$PROGDIR/dotfiles/bashrc" ]; then
        inf "Copying new Debian-based .bashrc file"
        exec_nonprv_cmd "cp $PROGDIR/dotfiles/bashrc /home/$DEV_USER/.bashrc"
      fi
    else
      exec_nonprv_cmd "cp /home/$DEV_USER/.bashrc /home/$DEV_USER/.bashrc-$TODAY"
    fi
    echo ""
  fi

  # handle .profile
  if [ -f "/home/$DEV_USER/.profile" ]; then
    if [ ! -f "/home/$DEV_USER/.profile-orig" ]; then

      # first verify that .profile hasn't been modified by another install function (e.g. golang)
      if [ -d "/home/$DEV_USER/.bootstrap/touched-dotprofile" ]; then
        echo ""
        error "Can't replace .profile 'cause it's already been modified."
        error "The files in the following directory indicate which install functions touched the .profile file:"
        error "   /home/$DEV_USER/.bootstrap/touched-dotprofile/*"
        echo ""
        error "To use a new .profile, you'll need to manually merge differences. Sorry."
        exit 1
      fi

      inf "Backing up .profile file"
      exec_nonprv_cmd "cp /home/$DEV_USER/.profile /home/$DEV_USER/.profile-orig"

      if [ -f "$PROGDIR/dotfiles/profile" ]; then
        inf "Copying new .profile file"
        exec_nonprv_cmd "cp $PROGDIR/dotfiles/profile /home/$DEV_USER/.profile"
      fi
    else
      exec_nonprv_cmd "cp /home/$DEV_USER/.profile /home/$DEV_USER/.profile-$TODAY"
    fi
    echo ""
  fi

  if [ "$DEFAULT_USER" == 'root' ]; then
    exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER"
  fi

  mark_as_installed dotfiles
}


enable_vim()
{
  echo ""
  hdr "Enabling vim & pathogen..."
  echo ""

  local inst_dir="/home/$DEV_USER/.vim"
  exec_cmd "mkdir -p $inst_dir/autoload $inst_dir/colors"

  ## not quite sure yet which vim plugin manager to use
#  exec_cmd "curl -fLo $inst_dir/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  curl -LSso "$inst_dir/autoload/pathogen.vim" https://tpo.pe/pathogen.vim

  # some vim colors
  if [ -d "/home/$DEV_USER/projects/vim-colors-molokai" ]; then
    exec_cmd "cd /home/$DEV_USER/projects/vim-colors-molokai; git pull"
  else
    exec_cmd "git clone https://github.com/fatih/molokai /home/$DEV_USER/projects/vim-colors-molokai"
  fi

  if [ -f "/home/$DEV_USER/projects/vim-colors-molokai/colors/molokai.vim" ]; then
    exec_cmd "cp /home/$DEV_USER/projects/vim-colors-molokai/colors/molokai.vim $inst_dir/colors/molokai.vim"
  fi

  # some dot files
#  if [ -d "/home/$DEV_USER/projects/dotfiles" ]; then
#    exec_cmd "cd /home/$DEV_USER/projects/dotfiles; git pull"
#  else
#    exec_cmd "git clone https://github.com/fatih/dotfiles /home/$DEV_USER/projects/dotfiles"
#  fi

  exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER"
}


enable_pathogen_bundles()
{
  echo ""
  hdr "Enabling vim & pathogen bundles..."
  echo ""

  local inst_dir="/home/$DEV_USER/.vim/bundle"
  rm -rf "$inst_dir"; mkdir -p "$inst_dir"
  cd "$inst_dir" || exit 1

  inf "Re-populating pathogen bundles..."

  ## colors
  git clone git://github.com/altercation/vim-colors-solarized.git

  ## golang
  git clone https://github.com/fatih/vim-go.git

  ## json
  git clone https://github.com/elzr/vim-json.git

  ## yaml
  git clone https://github.com/avakhov/vim-yaml

  ## Ansible
  git clone https://github.com/pearofducks/ansible-vim

  ## Dockerfile
  git clone https://github.com/ekalinin/Dockerfile.vim.git \
  "$inst_dir/Dockerfile"

  ## Nerdtree
  git clone https://github.com/scrooloose/nerdtree.git

  ## Ruby
  git clone git://github.com/vim-ruby/vim-ruby.git

  ## Python
  git clone https://github.com/klen/python-mode.git

  ## Whitespace (hint: to see whitespace just :ToggleWhitespace)
  git clone git://github.com/ntpeters/vim-better-whitespace.git

  ## Git
  git clone http://github.com/tpope/vim-git

  ## Terraform
  git clone http://github.com/hashivim/vim-terraform

  ## gotests
  git clone https://github.com/buoto/gotests-vim

  if [ $MEM_TOTAL_KB -ge 1500000 ]; then
    enable_vim_ycm
    cd "$inst_dir"
  else
    warn "Your system requires at least 1.5 GB of memory to "
    warn "install the YouCompleteMe vim plugin. Skipping... "
  fi

  # handle .vimrc
  if [ -f "/home/$DEV_USER/.vimrc" ]; then
    inf "Backing up .vimrc file"
    cp "/home/$DEV_USER/.vimrc" "/home/$DEV_USER/.vimrc-$TODAY"
  fi

  if [ -f "$PROGDIR/dotfiles/vimrc" ]; then
    inf "Copying new .vimrc file"
    cp "$PROGDIR/dotfiles/vimrc" "/home/$DEV_USER/.vimrc"
  fi

  if [ "$DEFAULT_USER" == 'root' ]; then
    chown -R "$DEV_USER:$DEV_USER" "/home/$DEV_USER"
    chown -R "$DEV_USER:$DEV_USER" "$inst_dir"
  fi
}


enable_vim_ycm()
{
  echo ""
  hdr "Installing the YouCompleteMe vim plugin..."
  echo ""

  local inst_dir="/home/$DEV_USER/.vim/bundle"

  ## YouCompleteMe
  git clone https://github.com/valloric/youcompleteme
  cd "$inst_dir/youcompleteme"
  git submodule update --init --recursive
  local ycm_opts=

  if command_exists go; then
    ycm_opts="${ycm_opts} --gocode-completer"
  fi

  if command_exists node; then
    ycm_opts="${ycm_opts} --tern-completer"
  fi

  #ycm_opts="--all"

  if [ "$DEFAULT_USER" == 'root' ]; then
    su -c "$inst_dir/youcompleteme/install.py $ycm_opts" "$DEV_USER"
  else
    exec_nonprv_cmd "$inst_dir/youcompleteme/install.py $ycm_opts"
  fi
}


install_git_subrepo()
{
  echo ""
  hdr "Installing git-subrepo..."
  echo ""

  # pull down git-subrepo
  if [ -d "/home/$DEV_USER/projects/git-subrepo" ]; then
    cd /home/$DEV_USER/projects/git-subrepo; git pull
  else
    git clone https://github.com/ingydotnet/git-subrepo "/home/$DEV_USER/projects/git-subrepo"
  fi

  if [ -f "/home/$DEV_USER/.bash_profile" ]; then
    inf "Setting up .bash_profile"
    grep -q -F 'git-subrepo' "/home/$DEV_USER/.bash_profile" || echo 'source "$HOME/projects/git-subrepo/.rc"' >> "/home/$DEV_USER/.bash_profile"
  else
    inf "Setting up .profile"
    grep -q -F 'git-subrepo' "/home/$DEV_USER/.profile" || echo 'source "$HOME/projects/git-subrepo/.rc"' >> "/home/$DEV_USER/.profile"
  fi
}


### Habitat
# https://www.habitat.sh/docs/get-habitat/
###
install_habitat()
{
  echo ""
  inf "Installing Habitat..."
  echo ""

  local install=0

  if command_exists hab; then
    if [ $(hab --version | awk '{ print $2; exit }') == "${HABITAT_VER}/${HABITAT_VER_TS}" ]; then
      warn "habitat is already installed."
      install=2
    else
      inf "habitat is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/hab'
      install=1
    fi
  fi

  if [ $install -le 1 ]; then
    wget -O /tmp/habitat.tar.gz \
      "https://bintray.com/habitat/stable/download_file?file_path=linux%2Fx86_64%2Fhab-${HABITAT_VER}-${HABITAT_VER_TS}-x86_64-linux.tar.gz"
    tar zxvf /tmp/habitat.tar.gz -C /tmp

    chmod +x "/tmp/hab-${HABITAT_VER}-${HABITAT_VER_TS}-x86_64-linux/hab"
    exec_cmd "mv /tmp/hab-${HABITAT_VER}-${HABITAT_VER_TS}-x86_64-linux/hab /usr/local/bin/hab"

    rm -rf "/tmp/hab-${HABITAT_VER}-${HABITAT_VER_TS}-x86_64-linux"
    rm /tmp/habitat.tar.gz

    # set up hab group and user.
    # also add non-privileged user to hab group
    if [ $install -eq 0 ]; then
      exec_cmd 'groupadd -f hab'
      inf "added hab group"
      echo ""
      exec_cmd "useradd -g hab hab"

      if [ "$DEFAULT_USER" == 'root' ]; then
        chown -R "$DEV_USER:$DEV_USER" /usr/local/bin
        usermod -a -G hab "$DEV_USER"
      else
        exec_cmd "usermod -aG hab $DEV_USER"
        inf "added $DEV_USER to group hab"
      fi

      # User must log off for these changes to take effect
      LOGOFF_REQ=1
    fi
  fi

  if [ "$DEFAULT_USER" == 'root' ]; then
    chown -R "$DEV_USER:$DEV_USER" /usr/local/bin
  else
    exec_cmd "chown root:root /usr/local/bin/hab"
  fi
}


### Azure cli
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
###
#install_azure_orig()
#{
#  echo ""
#  inf "Installing Azure cli..."
#  echo ""
#
#  local install=0
#
#  if command_exists az; then
#    if [ $(az --version | awk '{ print $2; exit }') == "($AZURE_VER)" ]; then
#      warn "azure cli is already installed."
#      install=1
#    else
#      inf "azure cli is already installed...but versions don't match"
#    fi
#  fi
#
#  if [ $install -eq 0 ]; then
#    wget -O /tmp/azure-cli.sh https://aka.ms/InstallAzureCli
#    #chmod +x /tmp/azure-cli.sh
#    exec_cmd 'bash /tmp/azure-cli.sh'
#
#    rm /tmp/azure-cli.sh
#  fi
#
#  if [ "$DEFAULT_USER" == 'root' ]; then
#    chown -R "$DEV_USER:$DEV_USER" /usr/local/bin
#  fi
#}



### ansible
# http://docs.ansible.com/ansible/intro_installation.html#latest-releases-via-pip
###
install_ansible()
{
  echo ""
  inf "Installing Ansible..."
  echo ""

 if command_exists ansible; then
    local version="$(ansible --version | awk '{ print $2; exit }')"
    semverParse $version
    warn "Ansible $version is already installed...skipping installation"
    return 0
  fi

  exec_cmd 'pip install git+git://github.com/ansible/ansible.git@devel'
  exec_cmd 'pip install ansible-lint'
}


### kops
# https://github.com/kubernetes/kops#linux
###
install_kops()
{
  echo ""
  inf "Installing Kubernetes Kops..."
  echo ""

  local inst_dir="/usr/local/bin"

  if command_exists kops; then
    warn "kops is already installed...will re-install"
    exec_cmd 'rm /usr/local/bin/kops'
  fi

  wget -O /tmp/kops "https://github.com/kubernetes/kops/releases/download/${KOPS_VER}/kops-linux-amd64"
  chmod +x /tmp/kops
  exec_cmd 'mv /tmp/kops /usr/local/bin/kops'
}


### hyper.sh
# https://www.hyper.sh/
###
install_hyper()
{
  echo ""
  inf "Installing Hyper.sh..."
  echo ""

  local inst_dir="/usr/local/bin"

  if command_exists hyper; then
    warn "hyper is already installed...will re-install"
    exec_cmd 'rm /usr/local/bin/hyper'
  fi

  wget -O /tmp/hyper-linux.tar.gz \
    "https://hyper-install.s3.amazonaws.com/hyper-linux-x86_64.tar.gz"
  tar zxvf /tmp/hyper-linux.tar.gz -C /tmp

  chmod +x /tmp/hyper
  exec_cmd 'mv /tmp/hyper /usr/local/bin/hyper'
  rm /tmp/hyper-linux.tar.gz
}


### CoreOS kube-aws
# https://coreos.com/kubernetes/docs/latest/kubernetes-on-aws.html#download-kube-aws
###
install_kube_aws()
{
  echo ""
  inf "Installing CoreOS kube-aws..."
  echo ""

  local inst_dir="/usr/local/bin"

  # Import the CoreOS Application Signing Public Key
  gpg2 --keyserver pgp.mit.edu --recv-key FC8A365E

  # Validated imported key
  #gpg2 --fingerprint FC8A365E | grep -i "18AD 5014 C99E F7E3 BA5F 6CE9 50BD D3E0 FC8A 365E"

  if command_exists kube-aws; then
    warn "kube-aws is already installed...will re-install"
    exec_cmd 'rm /usr/local/bin/kube-aws'
  fi

  wget -O /tmp/kube-aws.tar.gz "https://github.com/kubernetes-incubator/kube-aws/releases/download/v${KUBE_AWS_VER}/kube-aws-linux-amd64.tar.gz"
  tar zxvf /tmp/kube-aws.tar.gz -C /tmp

  chmod +x /tmp/linux-amd64/kube-aws
  exec_cmd 'mv /tmp/linux-amd64/kube-aws /usr/local/bin/kube-aws'
  rm /tmp/kube-aws.tar.gz
  rm -rf /tmp/linux-amd64
}


### kubectl cli
# http://kubernetes.io/docs/user-guide/prereqs/
###
install_kubectl()
{
  echo ""
  inf "Installing kubectl CLI..."
  echo ""

  local install=0

  if command_exists kubectl; then
    local kubectl_loc=$(which kubectl)
    if [ "$kubectl_loc" == "/home/$DEV_USER/bin/google-cloud-sdk/bin/kubectl" ]; then
      error "it appears kubectl was installed using the google cloud sdk."
      error "if you want to install using this --kubectl option;"
      error "  then first uninstall gcloud version using 'gcloud components remove kubectl'"
      exit 1
    fi

    if [ $(kubectl version | awk '{ print $5; exit }' | grep "v$KUBE_VER") ]; then
      warn "kubectl is already installed."
      install=1
    else
      inf "kubectl is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/kubectl'
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O "/tmp/kubernetes.tar.gz" \
      "https://github.com/kubernetes/kubernetes/releases/download/v${KUBE_VER}/kubernetes.tar.gz"
    tar -zxvf /tmp/kubernetes.tar.gz -C /tmp
    "/tmp/kubernetes/cluster/get-kube-binaries.sh"
    cp /tmp/kubernetes/client/bin/kube* "/home/$DEV_USER/bin/"

    rm /tmp/kubernetes.tar.gz
    rm -rf /tmp/kubernetes
  fi
}


### helm cli
# https://github.com/kubernetes/helm
###
install_helm()
{
  echo ""
  inf "Installing helm CLI..."
  echo ""

  local install=0

  if command_exists helm; then
    if [ $(helm version | awk -F: '{ print $3; exit }' | awk -F, '{ print $1; exit }' 2>/dev/null | grep "v${HELM_VER}") ]; then
      warn "helm is already installed."
      install=1
    else
      inf "helm is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/helm'
      exec_cmd 'rm /usr/local/bin/tiller'
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O /tmp/helm.tar.gz \
      "https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VER}-linux-amd64.tar.gz"
    tar -zxvf /tmp/helm.tar.gz -C /tmp
    exec_cmd 'cp /tmp/linux-amd64/helm /usr/local/bin/'
    rm /tmp/helm.tar.gz
    rm -rf "/tmp/linux-amd64"
  fi
}


### bosh cli
# https://bosh.io
###
install_bosh()
{
  echo ""
  inf "Installing bosh CLI..."
  echo ""

  local install=0

  if ! function_exists bosh_deps_install; then
    error "bosh 'create-env' dependency install function doesn't exist."
    exit 1
  fi

  if command_exists bosh; then
    if [ $(bosh --version | awk '{ print $2; exit }' | awk -F- '{ print $1; exit }' 2>/dev/null | grep "${BOSH_VER}") ]; then
      warn "bosh is already installed."
      install=1
    else
      inf "bosh is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/bosh'
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O /tmp/bosh \
      "https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${BOSH_VER}-linux-amd64"
    chmod +x /tmp/bosh
    exec_cmd 'mv /tmp/bosh /usr/local/bin/'

    # install 'create-env' dependencies
    bosh_deps_install
  fi
}


### draft
# https://github.com/kubernetes/helm
###
install_draft()
{
  echo ""
  inf "Installing draft..."
  echo ""

  local install=0

  if ! command_exists minikube; then
    error "draft requires minikube. First install minikube and then re-try the installation of draft."
    exit 1
  fi

  if command_exists draft; then
    if [ $(draft version | awk -F: '{ print $3; exit }' | awk -F, '{ print $1; exit }' 2>/dev/null | grep "v${DRAFT_VER}") ]; then
      warn "draft is already downloaded."
      install=1
    else
      inf "draft is already downloaded...but versions don't match"
      exec_cmd 'rm /usr/local/bin/draft'
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O /tmp/draft.tar.gz \
      "https://github.com/Azure/draft/releases/download/v${DRAFT_VER}/draft-v${DRAFT_VER}-linux-amd64.tar.gz"
    tar -zxvf /tmp/draft.tar.gz -C /tmp
    exec_cmd 'cp /tmp/linux-amd64/draft /usr/local/bin/'
    rm /tmp/draft.tar.gz
    rm -rf "/tmp/linux-amd64"

    warn "draft has been (re-)downloaded and extracted into your path."
    warn "  However, draft has not been installed. And installation is a bit more complicated than just dowloading."
    warn "  Go to https://github.com/Azure/draft/blob/v${DRAFT_VER}/docs/install.md to learn how to complete the installation."
  else
    warn "While draft has already been downloaded, it may not have been fully installed."
    warn "  And installation is a bit more complicated than just dowloading."
    warn "  Go to https://github.com/Azure/draft/blob/v${DRAFT_VER}/docs/install.md to learn how to complete the installation."
  fi
}


### minikube
# https://github.com/kubernetes/minikube
###
install_minikube()
{
  echo ""
  inf "Installing minikube..."
  echo ""

  local install=0

  if ! command_exists kubectl; then
    error "minikube requires kubectl. First install kubectl and then re-try the installation of minikube."
    exit 1
  fi

  if function_exists install_kvm; then
    install_kvm
  else
    error "attempting to install kvm as part of this minikube install. But the expected kvm install script was not found."
  fi

  if command_exists minikube; then
    if [ $(minikube version | awk -F: '{ print $3; exit }' | awk -F, '{ print $1; exit }' 2>/dev/null | grep "v${MINIKUBE_VER}") ]; then
      warn "minikube is already installed."
      install=1
    else
      inf "minikube is already installed...but versions don't match"
      exec_cmd 'rm /usr/local/bin/helm'
      exec_cmd 'rm /usr/local/bin/tiller'
    fi
  fi

  if [ $install -eq 0 ]; then
    wget -O /tmp/minikube \
      "https://storage.googleapis.com/minikube/releases/v${MINIKUBE_VER}/minikube-linux-amd64"
    chmod +x /tmp/minikube
    exec_cmd 'mv /tmp/minikube /usr/local/bin/'
  fi
}


### protocol buffers
# https://developers.google.com/protocol-buffers/
###
install_protobuf()
{
  echo ""
  inf "Installing protocol buffers..."
  echo ""
  local install_proto=0

  if command_exists protoc; then
    if [ $(protoc --version | awk '{ print $2; exit }') == "$PROTOBUF_VER" ]; then
      warn "protoc is already installed."
      install_proto=1
    else
      inf "protoc is already installed...but versions don't match"
    fi
  fi

  if [ $install_proto -eq 0 ]; then
    wget -O /tmp/protoc.tar.gz "https://github.com/google/protobuf/archive/v${PROTOBUF_VER}.tar.gz"
    tar -zxvf /tmp/protoc.tar.gz -C /tmp
    rm /tmp/protoc.tar.gz
    cd "/tmp/protobuf-${PROTOBUF_VER}" || exit 1
    ./autogen.sh
    ./configure
    make
    make check

    if [ "$DEFAULT_USER" != 'root' ]; then
      sudo make install
      sudo ldconfig
    else
      make install
      ldconfig
    fi

    rm -rf "/tmp/linux-amd64"
    cd -
  fi
}


### ssh key generation for gce
# https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys#project-wide
###
#create_gcloud_creds()
#{
#  local expir_date=$(date -d "+30 days" --utc --iso-8601='seconds')
#  su -c "ssh-keygen -b 2048 -t rsa -f ~/.ssh/google_compute_engine -C $DEV_USER -q -N \"\"" $DEV_USER
#  sed -i -e 's@pinterb@google-ssh {"userName":"pinterb","expireOn":"###EXPIRDT###"}@' ~/.ssh/google_compute_engine.pub
#  sed -i -e "s@###EXPIRDT###@${EXPIR_DT}@"  ~/.ssh/google_compute_engine.pub
#  sed -i -e "s@ssh-rsa@pinterb:ssh-rsa@" ~/.ssh/google_compute_engine.pub
#  su -c "chmod 400 ~/.ssh/google_compute_engine" pinterb
#}


main() {
  # Be unforgiving about errors
  set -euo pipefail
  readonly SELF="$(absolute_path $0)"
  cmdline $ARGS
  distro_check
  valid_args
  prerequisites

  # base packages, files, etc.
  if [ -n "$INSTALL_BASE" ]; then
    install_base
  fi

  if ! is_installed basepkgs; then
    error "base setup should be performed before installing anything else"
    exit 1
  fi

  # dot files
  if [ -n "$INSTALL_DOTFILES" ]; then
    install_dotfiles
  fi

  # tls utilities
  if [ -n "$INSTALL_TLS" ]; then
    source "${PROGDIR}/security/tls.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_tls
    else
      install_tls
    fi
  fi

  # golang handler
  if [ -n "$INSTALL_GOLANG" ]; then
    source "${PROGDIR}/lang/golang.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_golang
    else
      install_golang
    fi
  fi

  # node.js handler
  if [ -n "$INSTALL_NODE" ]; then
    if [ -n "$UNINSTALL" ]; then
      uninstall_node
    else
      install_node
    fi
  fi

  # ngrok handler
  if [ -n "$INSTALL_NGROK" ]; then
    source "${PROGDIR}/misc/ngrok.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_ngrok
    else
      install_ngrok
    fi
  fi

  # terraform handler
  if [ -n "$INSTALL_TERRAFORM" ]; then
    source "${PROGDIR}/misc/terraform.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_terraform
    else
      install_terraform
    fi
  fi

  # gcloud handler
  if [ -n "$INSTALL_GCLOUD" ]; then
    source "${PROGDIR}/cloud/gcloud.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_gcloud
    else
      install_gcloud
    fi
  fi

  # aws handler
  if [ -n "$INSTALL_AWS" ]; then
    source "${PROGDIR}/cloud/aws.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_aws
    else
      install_aws
    fi
  fi

  # azure cli handler
  if [ -n "$INSTALL_AZURE" ]; then
    if [ -n "$UNINSTALL" ]; then
      uninstall_azure
    else
      install_azure
    fi
  fi

  # digitalocean handler
  if [ -n "$INSTALL_DO" ]; then
    source "${PROGDIR}/cloud/digitalocean.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_doctl
    else
      install_doctl
    fi
  fi



  # vim handler
  if [ -n "$INSTALL_VIM" ]; then
    enable_vim
    enable_pathogen_bundles
  fi

  # ansible handler
  if [ -n "$INSTALL_ANSIBLE" ]; then
    install_ansible
  fi

  # docker handler
  if [ -n "$INSTALL_DOCKER" ]; then
    install_docker
  fi

  # kubectl handler
  if [ -n "$INSTALL_KUBECTL" ]; then
    install_kubectl
  fi

  # protobuf support (compile from source)
  if [ -n "$INSTALL_PROTO_BUF" ]; then
    install_protobuf
  fi

  # kops handler
  if [ -n "$INSTALL_KOPS" ]; then
    install_terraform
    install_kops
  fi

  # kube-aws handler
  if [ -n "$INSTALL_KUBE_AWS" ]; then
    install_aws
    install_kube_aws
  fi

  if [ -n "$INSTALL_SERVERLESS" ]; then
    #install_node
    install_serverless
  fi

  if [ -n "$INSTALL_HYPER" ]; then
    install_hyper
  fi

  if [ -n "$INSTALL_HABITAT" ]; then
    install_habitat
  fi

  if [ -n "$INSTALL_HELM" ]; then
    install_helm
  fi

  if [ -n "$INSTALL_MINIKUBE" ]; then
    install_minikube
  fi

  if [ -n "$INSTALL_DRAFT" ]; then
    install_draft
  fi

  if [ -n "$INSTALL_BOSH" ]; then
    install_bosh
  fi

  # always the last step, notify use to logoff for changes to take affect
  if [ $LOGOFF_REQ -eq 1 ]; then
    echo ""
    echo ""
    warn "*******************************"
    warn "* For changes to take effect, *"
    warn "* you must first log off!     *"
    warn "*******************************"
    echo ""
  fi

}

[[ "$0" == "$BASH_SOURCE" ]] && main
