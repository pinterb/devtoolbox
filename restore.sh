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

# misc. flags
LOGOFF_REQ=0

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
    --user <userid>        non-privileged user account to be restored (NOTE: this is an invalid option when running as non-privileged user)

    --exclude-base-setup   exclude base setup modifications from restore. Remove all other third-party utilities (incl. $UNINST_SUPPORT).

    -h --help              show this help


  Examples:
    $PROGNAME --exclude-base-setup

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

  # handle .bash_profile
  if [ -f "/home/$DEV_USER/.bash_profile" ]; then
    if [ -f "/home/$DEV_USER/.bash_profile-orig" ]; then
      inf "Restoring .bash_profile file"
      exec_nonprv_cmd "cp /home/$DEV_USER/.bash_profile-orig /home/$DEV_USER/.bash_profile"
      exec_nonprv_cmd "rm /home/$DEV_USER/.bash_profile-orig"

    else
      warn ".bash_profile backup file doesn't exist"
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

  # handle .gitconfig
  if [ -f "/home/$DEV_USER/.bootstrap/backup/orig/dotgitconfig" ]; then
    exec_cmd "cp /home/$DEV_USER/.bootstrap/backup/orig/dotgitconfig /home/$DEV_USER/.gitconfig"
  fi

  if [ "$DEFAULT_USER" == 'root' ]; then
    exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER"
  fi

  # handle .aliases
  if [ -f "/home/$DEV_USER/.bootstrap/backup/orig/dotaliases" ]; then
    exec_cmd "cp /home/$DEV_USER/.bootstrap/backup/orig/dotaliases /home/$DEV_USER/.aliases"
  fi

  # handle .functions
  if [ -f "/home/$DEV_USER/.bootstrap/backup/orig/dotfunctions" ]; then
    exec_cmd "cp /home/$DEV_USER/.bootstrap/backup/orig/dotfunctions /home/$DEV_USER/.functions"
  fi

  if [ "$DEFAULT_USER" == 'root' ]; then
    exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER"
  fi

  mark_as_uninstalled dotfiles
}


## Remove everything under ~/.bootstrap/installed
uninstall_deltas()
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
        tls)
          source "${PROGDIR}/security/tls.sh"
          uninstall_tls
          ;;
        golang)
          source "${PROGDIR}/lang/golang.sh"
          uninstall_golang
          ;;
        node)
          uninstall_serverless
          uninstall_node
          ;;
        ngrok)
          source "${PROGDIR}/misc/ngrok.sh"
          uninstall_ngrok
          ;;
        terraform)
          source "${PROGDIR}/misc/terraform.sh"
          uninstall_terraform
          ;;
        gcloud)
          source "${PROGDIR}/cloud/gcloud.sh"
          uninstall_gcloud
          ;;
        awscli)
          source "${PROGDIR}/cloud/aws.sh"
          uninstall_aws
          ;;
        azurecli)
          uninstall_azure
          ;;
        doctl)
          source "${PROGDIR}/cloud/digitalocean.sh"
          uninstall_doctl
          ;;
        vimsrc)
          source "${PROGDIR}/misc/vim.sh"
          uninstall_vim
          ;;
        vimmods)
          source "${PROGDIR}/misc/vim.sh"
          uninstall_vim_mods
          ;;
        vimbundles)
          source "${PROGDIR}/misc/vim.sh"
          restore_vim_bundles
          ;;
        ansible)
          source "${PROGDIR}/cfgmgmt/ansible.sh"
          uninstall_ansible
          ;;
        docker)
          uninstall_docker
          ;;
        kubectl)
          source "${PROGDIR}/k8s/kubectl.sh"
          uninstall_kubectl
          ;;
        helm)
          source "${PROGDIR}/k8s/helm.sh"
          uninstall_helm
          ;;
        xfce)
          uninstall_xfce
          ;;
        protobuf)
          source "${PROGDIR}/misc/protobuf.sh"
          uninstall_protobuf
          ;;
        jfrog)
          source "${PROGDIR}/misc/jfrog.sh"
          uninstall_jfrog
          ;;
        serverless)
          uninstall_serverless
          ;;
        bosh)
          source "${PROGDIR}/misc/bosh.sh"
          uninstall_bosh
          ;;
        kops)
          source "${PROGDIR}/k8s/kops.sh"
          uninstall_kops
          ;;
        hyper)
          source "${PROGDIR}/cloud/hyper.sh"
          uninstall_hyper
          ;;
        habitat)
          source "${PROGDIR}/misc/habitat.sh"
          uninstall_habitat
          ;;
        minikube)
          source "${PROGDIR}/k8s/minikube.sh"
          uninstall_minikube
          ;;
        draft)
          source "${PROGDIR}/k8s/draft.sh"
          uninstall_draft
          ;;
        vscode)
          uninstall_vscode
          ;;
        keybase)
          uninstall_keybase
          ;;
        inspec)
          uninstall_inspec
          ;;
        bazel)
          uninstall_bazel
          ;;
        jenkinsx)
          source "${PROGDIR}/k8s/jenkinsx.sh"
          uninstall_jenkinsx
          ;;
        skaffold)
          source "${PROGDIR}/k8s/skaffold.sh"
          uninstall_skaffold
          ;;
        goreleaser)
          source "${PROGDIR}/misc/goreleaser.sh"
          uninstall_goreleaser
          ;;
        prototool)
          source "${PROGDIR}/misc/prototool.sh"
          uninstall_prototool
          ;;
        fish)
          source "${PROGDIR}/misc/fish.sh"
          uninstall_fish
          ;;
        kustomize)
          source "${PROGDIR}/k8s/kustomize.sh"
          uninstall_kustomize
          ;;
        rustup)
          source "${PROGDIR}/lang/rustup.sh"
          uninstall_rustup
          ;;
        pulumi)
          source "${PROGDIR}/cloud/pulumi.sh"
          uninstall_pulumi
          ;;
        terragrunt)
          source "${PROGDIR}/misc/terragrunt.sh"
          uninstall_terragrunt
          ;;
        telepresence)
          source "${PROGDIR}/k8s/telepresence.sh"
          uninstall_telepresence
          ;;
        rbenv)
          uninstall_rbenv
          ;;
        sdkman)
          source "${PROGDIR}/misc/sdkman.sh"
          uninstall_sdkman
          ;;
        kubebuilder)
          source "${PROGDIR}/k8s/kubebuilder.sh"
          uninstall_kubebuilder
          ;;
        krew)
          source "${PROGDIR}/k8s/krew.sh"
          uninstall_krew
          ;;
        opa)
          source "${PROGDIR}/misc/opa.sh"
          uninstall_opa
          ;;
        tilt)
          source "${PROGDIR}/k8s/tilt.sh"
          uninstall_tilt
          ;;
        step)
          source "${PROGDIR}/security/step.sh"
          uninstall_step
          ;;
        gitcomm)
          source "${PROGDIR}/misc/gitcomm.sh"
          uninstall_gitcomm
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

  uninstall_deltas

  # restore base packages, files, etc.
  if [ -z "$EXCLUDE_BASE" ]; then
#    if ! is_installed basepkgs; then
#      error "base setup should be performed before installing anything else"
#      exit 1
#    fi
    restore_baseline
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
