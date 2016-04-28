#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

# http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"
readonly ARGS="$@"

# pull in utils
source "${PROGDIR}/utils.sh"

# cli arguments
INSTALL_TERRAFORM=


usage() {
  cat <<- EOF
  usage: $PROGNAME options

  $PROGNAME enables the bootstrapping of a Terraform installation for a non-privileged user.
  This script is typically used when new Linux vm's are provisioned and you want to bootstrap
  an environment for a new, non-privileged user.

  OPTIONS:
    -i --install             install Terraform 
    -h --help                show this help


  Examples:
    $PROGNAME --install
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
      --install)        args="${args}-i ";;
      --help)           args="${args}-h ";;
      #pass through anything else
      *) [[ "${arg:0:1}" == "-" ]] || delim="\""
          args="${args}${delim}${arg}${delim} ";;
    esac
  done

  #Reset the positional parameters to the short options
  eval set -- $args

  while getopts ":ih" OPTION
  do
     case $OPTION in
     i)
         readonly INSTALL_TERRAFORM=1
         ;;
     h)
         usage
         exit 0
         ;;
     \:)
         error "  argument missing from -$OPTARG option"
         echo ""
         usage
         exit 1
         ;;
     \?)
         error "  unknown option: -$OPTARG"
         echo ""
         usage
         exit 1
         ;;
    esac
  done

  return 0
}


# Make sure we have all the right stuff
prerequisites() {
  local git_cmd=`which git`
  local unzip_cmd=`which curl`
  
  if [ -z "$git_cmd" ]; then
    error "git does not appear to be installed. Please install and re-run this script."
    exit 1
  fi

  if [ -z "$unzip_cmd" ]; then
    error "unzip does not appear to be installed. Please install and re-run this script."
    exit 1
  fi

  # we don't want to be root to bootstrap
  if [ "$EUID" -eq 0 ]; then
    error "While you may need to sudo access, please do not run as root."
    exit 1
  fi
}


install_terraform()
{
  inf ""
  inf "installing Terraform..."

  rm -rf "$DOWNLOAD_DIR/install-terraform"
  git clone https://github.com/pinterb/install-terraform.sh "$DOWNLOAD_DIR/install-terraform"
  cd "$DOWNLOAD_DIR/install-terraform" || exit 1
  sudo ./install-terraform.sh
}


main() {
  # Be unforgiving about errors
  set -euo pipefail
  cmdline $ARGS
  prerequisites

  # terraform handler
  if [ -n "$INSTALL_TERRAFORM" ]; then
    install_terraform
  else
    warn "Currently --install is the only option available.  But you didn't select it.  So this was a no-op.  Is that okay?"
  fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main