#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

# http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"
readonly ARGS="$@"

# pull in utils
source "${PROGDIR}/utils.sh"

# cli arguments
DEV_USER=
ENABLE_ANSIBLE=
ENABLE_AWS=
ENABLE_DOCKER=
ENABLE_GOLANG=
ENABLE_GCLOUD=
ENABLE_TERRAFORM=


usage() {
  cat <<- EOF
  usage: $PROGNAME options

  $PROGNAME bootstraps all or some of a development environment for a new, non-privileged user.
  It downloads install scripts under the new user's home directory and enables .profile or .bash_profile
  to install specified development tools.

  OPTIONS:
    -u --user                non-privileged user account that gets bootstrapped (default: current user)
    -a --ansible             enable ansible
    -d --docker              enable docker
    -g --golang              enable golang (incl. third-party utilities)
    -y --gcloud              enable gcloud cli
    -t --terraform           enable terraform
    -y --gcloud              enable gcloud cli
    -z --aws                 enable aws cli
    -h --help                show this help


  Examples:
    $PROGNAME --user pinterb --golang
EOF
}


cmdline() {
  # got this idea from here:
  # http://kirk.webfinish.com/2009/10/bash-shell-script-to-use-getopts-with-gnu-style-long-positional-parameters/
  local arg=
  local args=
  for arg
  do
    local delim=""
    case "$arg" in
      #translate --gnu-long-options to -g (short options)
      --user)           args="${args}-u ";;
      --ansible)        args="${args}-a ";;
      --aws)            args="${args}-z ";;
      --docker)         args="${args}-d ";;
      --golang)         args="${args}-g ";;
      --gcloud)         args="${args}-y ";;
      --terraform)      args="${args}-t ";;
      --help)           args="${args}-h ";;
      #pass through anything else
      *) [[ "${arg:0:1}" == "-" ]] || delim="\""
          args="${args}${delim}${arg}${delim} ";;
    esac
  done

  #Reset the positional parameters to the short options
  eval set -- $args

  while getopts ":u:adgytzh" OPTION
  do
     case $OPTION in
     u)
         DEV_USER=$OPTARG
         ;;
     a)
         readonly ENABLE_ANSIBLE=1
         ;;
     d)
         readonly ENABLE_DOCKER=1
         ;;
     g)
         readonly ENABLE_GOLANG=1
         ;;
     y)
         readonly ENABLE_GCLOUD=1
         ;;
     t)
         readonly ENABLE_TERRAFORM=1
         ;;
     z)
         readonly ENABLE_AWS=1
         ;;
     h)
         usage
         exit 0
         ;;
     \:)
         echo "  argument missing from -$OPTARG option"
         echo ""
         usage
         exit 1
         ;;
     \?)
         echo "  unknown option: -$OPTARG"
         echo ""
         usage
         exit 1
         ;;
    esac
  done

  return 0
}


valid_args()
{
  # Check for required params
  if [[ -z "$DEV_USER" ]]; then
    error "a non-privileged user is required"
    echo  ""
    usage
    exit 1
  fi
}


# Make sure we have all the right stuff
prerequisites() {
  local git_cmd=`which git`

  if [ -z "$git_cmd" ]; then
    error "git does not appear to be installed. Please install and re-run this script."
    exit 1
  fi

  # we want to be root to bootstrap
  if [ "$EUID" -ne 0 ]; then
    error "Please run as root"
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


base_setup()
{
  su -c "mkdir -p /home/$DEV_USER/.bootstrap" "$DEV_USER"
}


enable_golang()
{
  local inst_dir="/home/$DEV_USER/.bootstrap/golang"
  inf ""
  inf "enabling golang..."

  rm -rf "$inst_dir"
  cp -R "$PROGDIR/golang" "$inst_dir"
  chown -R "$DEV_USER:$DEV_USER" "$inst_dir"

  cp "$inst_dir/golang_profile" "/home/$DEV_USER/.golang_profile"
  cp "$inst_dir/golang_verify" "/home/$DEV_USER/.golang_verify"
  sed -i -e "s@###MY_PROJECT_DIR###@/home/${DEV_USER}/.bootstrap/golang@" /home/$DEV_USER/.golang_verify

  if [ -f "/home/$DEV_USER/.bash_profile" ]; then
    inf "Setting up .bash_profile"
    grep -q -F 'source "$HOME/.golang_profile"' "/home/$DEV_USER/.bash_profile" || echo 'source "$HOME/.golang_profile"' >> "/home/$DEV_USER/.bash_profile"
    grep -q -F 'source "$HOME/.golang_verify"' "/home/$DEV_USER/.bash_profile" || echo 'source "$HOME/.golang_verify"' >> "/home/$DEV_USER/.bash_profile"
  else
    inf "Setting up .profile"
    grep -q -F 'source "$HOME/.golang_profile"' "/home/$DEV_USER/.profile" || echo 'source "$HOME/.golang_profile"' >> "/home/$DEV_USER/.profile"
    grep -q -F 'source "$HOME/.golang_verify"' "/home/$DEV_USER/.profile" || echo 'source "$HOME/.golang_verify"' >> "/home/$DEV_USER/.profile"
  fi
}


enable_terraform()
{
  local inst_dir="/home/$DEV_USER/.bootstrap/terraform"
  inf ""
  inf "enabling terraform..."

  rm -rf "$inst_dir"
  cp -R "$PROGDIR/terraform" "$inst_dir"
  chown -R "$DEV_USER:$DEV_USER" "$inst_dir"

  cp "$inst_dir/terraform_verify" "/home/$DEV_USER/.terraform_verify"
  sed -i -e "s@###MY_PROJECT_DIR###@/home/${DEV_USER}/.bootstrap/terraform@" /home/$DEV_USER/.terraform_verify

  if [ -f "/home/$DEV_USER/.bash_profile" ]; then
    inf "Setting up .bash_profile"
    grep -q -F 'source "$HOME/.terraform_verify"' "/home/$DEV_USER/.bash_profile" || echo 'source "$HOME/.terraform_verify"' >> "/home/$DEV_USER/.bash_profile"
  else
    inf "Setting up .profile"
    grep -q -F 'source "$HOME/.terraform_verify"' "/home/$DEV_USER/.profile" || echo 'source "$HOME/.terraform_verify"' >> "/home/$DEV_USER/.profile"
  fi
}


### google cloud platform cli
# https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu
###
enable_gcloud()
{
  local cloud_sdk_repo="cloud-sdk-$(lsb_release -c -s)"
  echo "deb http://packages.cloud.google.com/apt $cloud_sdk_repo main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  apt-get update && apt-get install google-cloud-sdk

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
  valid_args
  prerequisites
  base_setup

  # golang handler
  if [ -n "$ENABLE_GOLANG" ]; then
    enable_golang
  fi

  # terraform handler
  if [ -n "$ENABLE_TERRAFORM" ]; then
    enable_terraform
  fi

  # gcloud handler
  if [ -n "$ENABLE_GCLOUD" ]; then
    enable_gcloud
  fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main