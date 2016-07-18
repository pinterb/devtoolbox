#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

# http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"
readonly DOWNLOAD_DIR="/tmp"
readonly ARGS="$@"

# pull in utils
source "${PROGDIR}/utils.sh"

# pull in new golang profile
source "$PROGDIR/gcloud_profile"

# cli arguments
INSTALL_GCLOUD=


usage() {
  cat <<- EOF
  usage: $PROGNAME options

  $PROGNAME enables the bootstrapping of a Google Cloud SDK installation for a non-privileged user.
  This script is typically used when new Linux vm's are provisioned and you want to bootstrap
  an environment for a new, non-privileged user.

  OPTIONS:
    -i --install             install gcloud
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
         readonly INSTALL_GCLOUD=1
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
  local curl_cmd=`which curl`
  
  if [ -z "$git_cmd" ]; then
    error "git does not appear to be installed. Please install and re-run this script."
    exit 1
  fi

  if [ -z "$curl_cmd" ]; then
    error "curl does not appear to be installed. Please install and re-run this script."
    exit 1
  fi

  # we don't want to be root to bootstrap
  if [ "$EUID" -eq 0 ]; then
    error "While you may need to sudo access, please do not run as root."
    exit 1
  fi
}


local_setup()
{
  if [ ! -d "$HOME/bin" ]; then
    echo ""
    inf "Creating $HOME/bin"
    mkdir -p "$HOME"/bin
  fi

  inf "Setting up profile"
  cp "$PROGDIR/gcloud_profile" $HOME/.gcloud_profile

  echo ""
  if [ -f "$HOME/.bash_profile" ]; then
    inf "Setting up .bash_profile"
    grep -q -F 'source "$HOME/.gcloud_profile"' "$HOME/.bash_profile" || echo 'source "$HOME/.gcloud_profile"' >> "$HOME/.bash_profile"
  else
    inf "Setting up .profile"
    grep -q -F 'source "$HOME/.gcloud_profile"' "$HOME/.profile" || echo 'source "$HOME/.gcloud_profile"' >> "$HOME/.profile"
  fi
}


install_gcloud()
{
  inf ""
  inf "installing gcloud..."

  rm -rf "$DOWNLOAD_DIR/install-gcloud"
  git clone https://github.com/pinterb/install-gcloud.sh "$DOWNLOAD_DIR/install-gcloud"
  cd "$DOWNLOAD_DIR/install-gcloud" || exit 1
  bash install-gcloud.sh
}


main() {
  # Be unforgiving about errors
  set -euo pipefail
  cmdline $ARGS
  prerequisites
  local_setup

  # gcloud handler
  if [ -n "$INSTALL_GCLOUD" ]; then
    install_gcloud
  fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main
