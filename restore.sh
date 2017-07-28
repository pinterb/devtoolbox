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
EXCLUDE_BASE=

# list of packages with "uninstall" support
UNINST_SUPPORT="xfce, kubectl, azure, aws, gcloud, digitalocean, terraform, node.js, ngrok, tls, and golang"

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

  $PROGNAME attempts to restore a system to a state closely resembling that prior to using the $PROGDIR/bootstrap.sh script.
  It first attempts to uninstall any CLI's and other executables. It then restores base packages to original state.

  OPTIONS:
    --user <userid>        non-privileged user account to be bootstrapped (NOTE: invalid option when running as non-privileged user)

    --exclude-base-setup   exclude base setup modifications from restore. Remove all other third-party utilities (incl. $UNINST_SUPPORT).

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
      exclude-base-setup)
        readonly EXCLUDE_BASE=1
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
# restore baseline packages and files
###
restore_baseline()
{

  if function_exists base_restore; then
    if is_installed basepkgs; then
      base_restore orig
    else
      warn "base packages were not installed"
    fi
  else
    error "baseline restore function doesn't exist."
    exit 1
  fi

  if is_installed binfiles; then
    remove_binfiles
  else
    warn "binfiles were not installed"
  fi

  if is_installed dotfiles; then
    restore_dotfiles
  else
    warn "dot files were not installed"
  fi

}


remove_binfiles()
{
  echo ""
  inf "removing binfiles..."

  if [ -d "$PROGDIR/binfiles" ]; then
    for i in "$PROGDIR/binfiles"/*; do
      if [ -r $i ]; then
        local file=$(basename $i)
        if [ -f "/home/$DEV_USER/bin/$file" ]; then
          exec_cmd "rm /home/$DEV_USER/bin/$file"
        fi
      fi
    done
    unset i
  fi

  mark_as_uninstalled binfiles
}


###
# restore dot files
###
restore_dotfiles()
{
  if function_exists uninstall_dotfiles; then
    uninstall_dotfiles
  else
    error "dot files uninstall function doesn't exist."
    exit 1
  fi
}


uninstall_dotfiles()
{
  echo ""
  hdr "Removing dotfiles..."
  echo ""

  if [ "$DEFAULT_USER" == 'root' ]; then
    su -c "rm -rf /home/$DEV_USER/.bootstrap/profile.d"
  else
    rm -rf "/home/$DEV_USER/.bootstrap/profile.d"
  fi

  # handle .bashrc
  if [ -f "/home/$DEV_USER/.bashrc" ]; then
    if [ -f "/home/$DEV_USER/.bashrc-orig" ]; then
      inf "Restoring .bashrc file"
      exec_nonprv_cmd "cp /home/$DEV_USER/.bashrc-orig /home/$DEV_USER/.bashrc"
      exec_nonprv_cmd "rm /home/$DEV_USER/.bashrc-orig"

    else
      warn ".bashrc backup file doesn't exist"
    fi
    echo ""
  fi

  # handle .profile
  if [ -f "/home/$DEV_USER/.profile" ]; then
    if [ -f "/home/$DEV_USER/.profile-orig" ]; then
      inf "Restoring up .profile file"
      exec_nonprv_cmd "cp /home/$DEV_USER/.profile-orig /home/$DEV_USER/.profile"
      exec_nonprv_cmd "rm /home/$DEV_USER/.profile-orig"
    
    else
      warn ".profile backup file doesn't exist"
    fi
    echo ""
  fi

  if [ "$DEFAULT_USER" == 'root' ]; then
    exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER"
  fi

  mark_as_uninstalled dotfiles
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
  exec_cmd "curl -LSso $inst_dir/autoload/pathogen.vim https://tpo.pe/pathogen.vim"

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

#  if [ "$DEFAULT_USER" == 'root' ]; then
#    chown -R "$DEV_USER:$DEV_USER" "/home/$DEV_USER"
#    chown -R "$DEV_USER:$DEV_USER" "$inst_dir"
#  fi
  exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER"
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


## Remove everything under ~/.bootstrap/installed
remove_clis()
{
  echo ""
  inf "Uninstalling all third party cli's, utilities, etc..."

  if [ -d "/home/$DEV_USER/.bootstrap/installed" ]; then
    for i in "/home/$DEV_USER/.bootstrap/installed"/*; do
      if [ -r $i ]; then
        local file=$(basename $i)
        case "${file}" in
        basepkgs)
          ;;
        binfiles)
          ;;
        dotfiles)
          ;;
        golang)
          source "${PROGDIR}/lang/golang.sh"
          uninstall_golang
          ;;
        kubectl)
          source "${PROGDIR}/k8s/kubectl.sh"
          uninstall_kubectl
          ;;
        *)
          error "no uninstall handler found for \"$file\""
          ;;
        esac
      fi
    done
    unset i
  fi
}


main() {
  # Be unforgiving about errors
  set -euo pipefail
  readonly SELF="$(absolute_path $0)"
  cmdline $ARGS
  distro_check
  valid_args
  prerequisites

  remove_clis

  # restore base packages, files, etc.
  if [ -z "$EXCLUDE_BASE" ]; then
    if ! is_installed basepkgs; then
      error "base setup should be performed before installing anything else"
      exit 1
    fi
    restore_baseline
  fi

  exit 0 

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
    source "${PROGDIR}/cfgmgmt/ansible.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_ansible
    else
      install_ansible
    fi
  fi

  # docker handler
  if [ -n "$INSTALL_DOCKER" ]; then
    if [ -n "$UNINSTALL" ]; then
      uninstall_docker
    else
      install_docker
    fi
  fi

  # kubectl handler
  if [ -n "$INSTALL_KUBECTL" ]; then
    source "${PROGDIR}/k8s/kubectl.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_kubectl
    else
      install_kubectl
    fi
  fi

  if [ -n "$INSTALL_HELM" ]; then
    source "${PROGDIR}/k8s/helm.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_helm
    else
      install_helm
    fi
  fi

  # xfce handler (only for windows wsl!)
  if [ -n "$INSTALL_XFCE" ]; then
    if [ -n "$UNINSTALL" ]; then
      uninstall_xfce
    else
      install_xfce
    fi
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
