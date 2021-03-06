#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

# http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/

readonly PROGNAME=$(basename $0)
#readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"
readonly PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ARGS="$@"
readonly TODAY=$(date +%Y%m%d%H%M%S)

# pull in utils
source "${PROGDIR}/utils.sh"

# sys_arch discovers the architecture for this system.
sys_arch

# cli arguments
DEV_USER=
UNINSTALL=
INSTALL_BASE=
INSTALL_DOTFILES=
INSTALL_TLS=
INSTALL_ANSIBLE=
INSTALL_AWS=
INSTALL_KOPS=
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
INSTALL_XFCE=
INSTALL_JFROG=
INSTALL_VSCODE=
INSTALL_KEYBASE=
INSTALL_INSPEC=
INSTALL_BAZEL=
INSTALL_JENKINSX=
INSTALL_SKAFFOLD=
INSTALL_GORELEASER=
INSTALL_PROTOTOOL=
INSTALL_FISH=
INSTALL_KUSTOMIZE=
INSTALL_RUSTUP=
INSTALL_PULUMI=
INSTALL_TERRAGRUNT=
INSTALL_TELEPRESENCE=
INSTALL_RBENV=
INSTALL_SDKMAN=
INSTALL_KUBEBUILDER=
INSTALL_KREW=
INSTALL_OPA=
INSTALL_TILT=
INSTALL_STEP=
INSTALL_GITCOMM=
INSTALL_GOSWAGGER=

# misc. flags
SHOULD_WARM=0
LOGOFF_REQ=0

# list of packages with "uninstall" support
UNINST_SUPPORT="go-swagger, gitcomm, step, tilt, opa, krew, kubebuilder, sdkman, rbenv, telepresence, terragrunt, pulumi, rustup, kustomize, fish, prototool, goreleaser, skaffold, jenkins x, bazel, inspec, keybase, vscode, minikube, hyper, kops, bosh, serverless, xfce, kubectl, azure, aws, gcloud, digitalocean, terraform, node.js, ngrok, tls, and golang"


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
    --digitalocean         digitalocean cli
    --gcloud               gcloud cli
    --hyper                hyper.sh (Hyper.sh is a hypervisor-agnostic Docker runtime)
    --pulumi               pulumi is a Cloud Native Development Platform

    --ansible              ansible
    --docker               docker
    --terraform            terraform
    --terragrunt           terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules
    --bosh                 bosh cli

    --golang               golang (incl. third-party utilities)
    --habitat              habitat.sh (Habitat enables you to build and run your applications in a Cloud Native manner.)
    --node                 node.js
    --ballerina            Ballerina programming language
    --protobuf             protocol buffers (i.e. protoc)
    --serverless           various serverless utilities (e.g. serverless, apex, sparta)
    --prototool            a swiss army knife for protocol buffers
    --rustup               rustup is an installer for the systems programming language Rust
    --rbenv                rbenv is used to pick a Ruby version for your application and guarantee that your development environment matches production
    --sdkman               sdkman is a tool for managing parallel versions of multiple Java-based sdks on most Unix based systems

    --minikube             opinionated local development workflow for applications deployed to Kubernetes (github.com/Azure/draft)
    --kubectl              kubectl
    --helm                 helm
    --draft                opinionated local development workflow for applications deployed to Kubernetes (github.com/Azure/draft)
    --kops                 kops (a kubernetes provisioning tool)
    --skaffold             skaffold is a utility for streamlining local development of kubernetes-targeted workloads
    --kustomize            kustomize lets you customize raw, template-free YAML files for multiple purposes, leaving the original YAML untouched and usable as is
    --jenkinsx             jenkins x is a ci/cd platform for Kubernetes
    --telepresence         telepresence is a kubernetes utility for remote debugging
    --kubebuilder          kubebuilder is an SDK for rapidly building and publishing Kubernetes APIs in Go
    --krew                 krew is the package manager for kubectl plugins
    --tilt                 tilt is a workflow framework for local Kubernetes development

    --ngrok                create secure tunnels to localhost (ngrok.com)
    --jfrog                the universial cli to JFrog products (e.g. Artifactory, Bintray)
    --tls-utils            utilities for managing TLS certificates (e.g. letsencrypt, cfssl)
    --step                 step is a utility for building, operating, and automating systems that use zero trust technologies (e.g. TLS, OAuth, OTP, FIDO U2F)
    --keybase              Keybase
    --inspec               InSpec by Chef
    --goreleaser           GoReleaser is a release automation tool for Go projects
    --opa                  Open Policy Agent is policy-based control for cloud native environments
    --go-swagger           Swagger 2.0 implementation for Golang

    --vim                  vim-plug & choice plugins (e.g. vim-go)
    --vscode               Microsoft Visual Studio Code IDE

    --xfce                 XFCE window manager on Windows WSL
    --bazel                Bazel build tool
    --fish                 Fish is a cross-platform systems package manager, bringing the ease of use of Homebrew to Linux and Windows.
    --gitcomm              gitcomm is a git commit message formatter

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
      minikube)
        readonly INSTALL_MINIKUBE=1
        ;;
      ngrok)
        readonly INSTALL_NGROK=1
        ;;
      node)
        readonly INSTALL_NODE=1
        ;;
      protobuf)
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
      xfce)
        readonly INSTALL_XFCE=1
        ;;
      jfrog)
        readonly INSTALL_JFROG=1
        ;;
      vscode)
        readonly INSTALL_VSCODE=1
        ;;
      keybase)
        readonly INSTALL_KEYBASE=1
        ;;
      inspec)
        readonly INSTALL_INSPEC=1
        ;;
      bazel)
        readonly INSTALL_BAZEL=1
        ;;
      jenkinsx)
        readonly INSTALL_JENKINSX=1
        ;;
      skaffold)
        readonly INSTALL_SKAFFOLD=1
        ;;
      goreleaser)
        readonly INSTALL_GORELEASER=1
        ;;
      prototool)
        readonly INSTALL_PROTOTOOL=1
        ;;
      fish)
        readonly INSTALL_FISH=1
        ;;
      kustomize)
        readonly INSTALL_KUSTOMIZE=1
        ;;
      rustup)
        readonly INSTALL_RUSTUP=1
        ;;
      pulumi)
        readonly INSTALL_PULUMI=1
        ;;
      terragrunt)
        readonly INSTALL_TERRAGRUNT=1
        ;;
      telepresence)
        readonly INSTALL_TELEPRESENCE=1
        ;;
      rbenv)
        readonly INSTALL_RBENV=1
        ;;
      sdkman)
        readonly INSTALL_SDKMAN=1
        ;;
      kubebuilder)
        readonly INSTALL_KUBEBUILDER=1
        ;;
      krew)
        readonly INSTALL_KREW=1
        ;;
      opa)
        readonly INSTALL_OPA=1
        ;;
      tilt)
        readonly INSTALL_TILT=1
        ;;
      uninstall)
        readonly UNINSTALL=1
        ;;
      step)
        readonly INSTALL_STEP=1
        ;;
      gitcomm)
        readonly INSTALL_GITCOMM=1
        ;;
      go-swagger)
        readonly INSTALL_GOSWAGGER=1
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

  exec_cmd "mkdir -p /home/$DEV_USER/bin"
  exec_cmd "cp -R $PROGDIR/binfiles/. /home/$DEV_USER/bin"
  exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER/bin"

  if [[ -f "/home/$DEV_USER/bin/ks-linux-amd64" ]]; then
    mv "/home/$DEV_USER/bin/ks-linux-amd64" "/home/$DEV_USER/bin/ks"
  fi

  inf "updating ~/.bootstrap/profile.d/ with /home/$DEV_USER/bin ..."
  echo "# The following PATH was automatically added by $PROGDIR/$PROGNAME" > "/home/$DEV_USER/.bootstrap/profile.d/binfiles.sh"
  echo "export PATH=$PATH:/home/$DEV_USER/bin" >> "/home/$DEV_USER/.bootstrap/profile.d/binfiles.sh"

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

  if [ "$DEFAULT_USER" == 'root' ]; then
    su -c "mkdir -p /home/$DEV_USER/.bootstrap/profile.d" "$DEV_USER"
  else
    mkdir -p "/home/$DEV_USER/.bootstrap/profile.d"
  fi

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

  # handle .bash_profile
  if [ -f "/home/$DEV_USER/.bash_profile" ]; then
    if [ ! -f "/home/$DEV_USER/.bash_profile-orig" ]; then
      inf "Backing up .bash_profile file"
      exec_nonprv_cmd "cp /home/$DEV_USER/.bash_profile /home/$DEV_USER/.bash_profile-orig"

      if [ -f "$PROGDIR/dotfiles/bash_profile" ]; then
        inf "Copying new Debian-based .bash_profile file"
        exec_nonprv_cmd "cp $PROGDIR/dotfiles/bash_profile /home/$DEV_USER/.bash_profile"
      fi
    else
      exec_nonprv_cmd "cp /home/$DEV_USER/.bash_profile /home/$DEV_USER/.bash_profile-$TODAY"
    fi
    echo ""
  fi

  if [ -f "$PROGDIR/dotfiles/bash_profile" ]; then
    inf "Copying new .bash_profile file"
    exec_nonprv_cmd "cp $PROGDIR/dotfiles/bash_profile /home/$DEV_USER/.bash_profile"
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

  # handle .gitconfig
  if [ -f "/home/$DEV_USER/.gitconfig" ]; then
    if [ ! -f "/home/$DEV_USER/.bootstrap/backup/orig/dotgitconfig" ]; then
      inf "Backing up .gitconfig file"
      exec_nonprv_cmd "cp /home/$DEV_USER/.gitconfig /home/$DEV_USER/.bootstrap/backup/orig/dotgitconfig"
    else
      exec_nonprv_cmd "cp /home/$DEV_USER/.gitconfig /home/$DEV_USER/.gitconfig-$TODAY"
    fi
  fi

  if [ -f "$PROGDIR/dotfiles/gitconfig" ]; then
    inf "Copying new .gitconfig file"
    exec_nonprv_cmd "cp $PROGDIR/dotfiles/gitconfig /home/$DEV_USER/.gitconfig"
  fi

  # handle .aliases
  if [ -f "/home/$DEV_USER/.aliases" ]; then
    if [ ! -f "/home/$DEV_USER/.bootstrap/backup/orig/dotaliases" ]; then
      inf "Backing up .aliases file"
      exec_nonprv_cmd "cp /home/$DEV_USER/.aliases /home/$DEV_USER/.bootstrap/backup/orig/dotaliases"
    else
      exec_nonprv_cmd "cp /home/$DEV_USER/.aliases /home/$DEV_USER/.aliases-$TODAY"
    fi
  fi

  if [ -f "$PROGDIR/dotfiles/aliases" ]; then
    inf "Copying new .aliases file"
    exec_nonprv_cmd "cp $PROGDIR/dotfiles/aliases /home/$DEV_USER/.aliases"
  fi

  # handle .functions
  if [ -f "/home/$DEV_USER/.functions" ]; then
    if [ ! -f "/home/$DEV_USER/.bootstrap/backup/orig/dotfunctions" ]; then
      inf "Backing up .functions file"
      exec_nonprv_cmd "cp /home/$DEV_USER/.functions /home/$DEV_USER/.bootstrap/backup/orig/dotfunctions"
    else
      exec_nonprv_cmd "cp /home/$DEV_USER/.functions /home/$DEV_USER/.functions-$TODAY"
    fi
  fi

  if [ -f "$PROGDIR/dotfiles/functions" ]; then
    inf "Copying new .functions file"
    exec_nonprv_cmd "cp $PROGDIR/dotfiles/functions /home/$DEV_USER/.functions"
  fi

  # handle .tmux.conf
  if [ -f "/home/$DEV_USER/.tmux.conf" ]; then
    if [ ! -f "/home/$DEV_USER/.bootstrap/backup/orig/dottmux" ]; then
      inf "Backing up .tmux.conf file"
      exec_nonprv_cmd "cp /home/$DEV_USER/.tmux.conf /home/$DEV_USER/.bootstrap/backup/orig/dottmux"
    else
      exec_nonprv_cmd "cp /home/$DEV_USER/.tmux.conf /home/$DEV_USER/.tmux.conf-$TODAY"
    fi
  fi

  if [ -f "$PROGDIR/dotfiles/tmux.conf" ]; then
    inf "Copying new .tmux.conf file"
    exec_nonprv_cmd "cp $PROGDIR/dotfiles/tmux.conf /home/$DEV_USER/.tmux.conf"
  fi

  # handle .config/terminator/config
  local terminator_home="/home/$DEV_USER/.config/terminator"
  if [ -f "$terminator_home/config" ]; then
    if [ ! -f "/home/$DEV_USER/.bootstrap/backup/orig/dotconfigterminatorconfig" ]; then
      inf "Backing up terminator/config file"
      exec_nonprv_cmd "cp $terminator_home/config /home/$DEV_USER/.bootstrap/backup/orig/dotconfigterminatorconfig"
    else
      exec_nonprv_cmd "cp $terminator_home/config $terminator_home/config-$TODAY"
    fi
  fi

  if [ -f "$PROGDIR/dotfiles/terminator.config" ]; then
    inf "Copying new terminator/config file"
    exec_nonprv_cmd "rm -rf $terminator_home/config"
    exec_nonprv_cmd "cp $PROGDIR/dotfiles/terminator.config $terminator_home/config"
  fi

  if [ "$DEFAULT_USER" == 'root' ]; then
    exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER"
  fi

  mark_as_installed dotfiles
}


install_git_subrepo()
{

  if [ "$DEFAULT_USER" == 'root' ]; then
    exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER"
  fi

  mark_as_installed dotfiles
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
    source "${PROGDIR}/misc/vim.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_vim
      uninstall_vim_mods
      restore_vim_bundles
    else
      install_vim
      install_vim_mods
      enable_pathogen_bundles
    fi
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
    source "${PROGDIR}/misc/protobuf.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_protobuf
    else
      install_protobuf
    fi
  fi

  # jfrog handler
  if [ -n "$INSTALL_JFROG" ]; then
    source "${PROGDIR}/misc/jfrog.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_jfrog
    else
      install_jfrog
    fi
  fi

  # serverless utilies & various frameworks
  if [ -n "$INSTALL_SERVERLESS" ]; then
    if [ -n "$UNINSTALL" ]; then
      uninstall_serverless
    else
      install_serverless
    fi
  fi

  # BOSH cli handler
  if [ -n "$INSTALL_BOSH" ]; then
    source "${PROGDIR}/misc/bosh.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_bosh
    else
      install_bosh
    fi
  fi

  # kops handler
  if [ -n "$INSTALL_KOPS" ]; then
    source "${PROGDIR}/k8s/kops.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_kops
    else
      install_kops
    fi
  fi

  if [ -n "$INSTALL_HYPER" ]; then
    source "${PROGDIR}/cloud/hyper.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_hyper
    else
      install_hyper
    fi
  fi

  if [ -n "$INSTALL_HABITAT" ]; then
    source "${PROGDIR}/misc/habitat.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_habitat
    else
      install_habitat
    fi
  fi

  if [ -n "$INSTALL_MINIKUBE" ]; then
    source "${PROGDIR}/k8s/minikube.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_minikube
    else
      install_minikube
    fi
  fi

  if [ -n "$INSTALL_DRAFT" ]; then
    source "${PROGDIR}/k8s/draft.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_draft
    else
      install_draft
    fi
  fi

  if [ -n "$INSTALL_VSCODE" ]; then
    if [ -n "$UNINSTALL" ]; then
      uninstall_vscode
    else
      install_vscode
    fi
  fi

  if [ -n "$INSTALL_KEYBASE" ]; then
    if [ -n "$UNINSTALL" ]; then
      uninstall_keybase
    else
      install_keybase
    fi
  fi

  if [ -n "$INSTALL_INSPEC" ]; then
    if [ -n "$UNINSTALL" ]; then
      uninstall_inspec
    else
      install_inspec
    fi
  fi

  if [ -n "$INSTALL_BAZEL" ]; then
    if [ -n "$UNINSTALL" ]; then
      uninstall_bazel
    else
      install_bazel
    fi
  fi

  if [ -n "$INSTALL_JENKINSX" ]; then
    source "${PROGDIR}/k8s/jenkinsx.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_jenkinsx
    else
      install_jenkinsx
    fi
  fi

  if [ -n "$INSTALL_SKAFFOLD" ]; then
    source "${PROGDIR}/k8s/skaffold.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_skaffold
    else
      install_skaffold
    fi
  fi

  if [ -n "$INSTALL_GORELEASER" ]; then
    source "${PROGDIR}/misc/goreleaser.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_goreleaser
    else
      install_goreleaser
    fi
  fi

  if [ -n "$INSTALL_PROTOTOOL" ]; then
    source "${PROGDIR}/misc/prototool.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_prototool
    else
      install_prototool
    fi
  fi

  if [ -n "$INSTALL_FISH" ]; then
    source "${PROGDIR}/misc/fish.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_fish
    else
      install_fish
    fi
  fi

  if [ -n "$INSTALL_KUSTOMIZE" ]; then
    source "${PROGDIR}/k8s/kustomize.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_kustomize
    else
      install_kustomize
    fi
  fi

  if [ -n "$INSTALL_RUSTUP" ]; then
    source "${PROGDIR}/lang/rustup.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_rustup
    else
      install_rustup
    fi
  fi

  if [ -n "$INSTALL_PULUMI" ]; then
    source "${PROGDIR}/cloud/pulumi.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_pulumi
    else
      install_pulumi
    fi
  fi

  if [ -n "$INSTALL_TERRAGRUNT" ]; then
    source "${PROGDIR}/misc/terragrunt.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_terragrunt
    else
      install_terragrunt
    fi
  fi

  if [ -n "$INSTALL_TELEPRESENCE" ]; then
    source "${PROGDIR}/k8s/telepresence.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_telepresence
    else
      install_telepresence
    fi
  fi

  if [ -n "$INSTALL_RBENV" ]; then
    if [ -n "$UNINSTALL" ]; then
      uninstall_rbenv
    else
      install_rbenv
    fi
  fi

  if [ -n "$INSTALL_SDKMAN" ]; then
    source "${PROGDIR}/misc/sdkman.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_sdkman
    else
      install_sdkman
    fi
  fi

  if [ -n "$INSTALL_KUBEBUILDER" ]; then
    source "${PROGDIR}/k8s/kubebuilder.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_kubebuilder
    else
      install_kubebuilder
    fi
  fi

  if [ -n "$INSTALL_KREW" ]; then
    source "${PROGDIR}/k8s/krew.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_krew
    else
      install_krew
    fi
  fi

  if [ -n "$INSTALL_OPA" ]; then
    source "${PROGDIR}/misc/opa.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_opa
    else
      install_opa
    fi
  fi

  if [ -n "$INSTALL_TILT" ]; then
    source "${PROGDIR}/k8s/tilt.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_tilt
    else
      install_tilt
    fi
  fi

  if [ -n "$INSTALL_STEP" ]; then
    source "${PROGDIR}/security/step.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_step
    else
      install_step
    fi
  fi

  if [ -n "$INSTALL_GITCOMM" ]; then
    source "${PROGDIR}/misc/gitcomm.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_gitcomm
    else
      install_gitcomm
    fi
  fi

  if [ -n "$INSTALL_GOSWAGGER" ]; then
    source "${PROGDIR}/misc/go-swagger.sh"
    if [ -n "$UNINSTALL" ]; then
      uninstall_goswagger
    else
      install_goswagger
    fi
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
