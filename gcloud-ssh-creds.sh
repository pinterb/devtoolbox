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
FORCE_OVERWRITE=
OUTPUT_FILE="google_compute_engine"
GCLOUD_USERNAME=
REMOTE_SSH_USER=
EXPIRE_DAYS="45"


usage() {
  cat <<- EOF
  usage: $PROGNAME options

  $PROGNAME creates a google cloud ssh key pair for a new, non-privileged user.

  OPTIONS:
    -u --user                non-privileged user account that gets bootstrapped (default: current user)
    -a --account-name        google cloud account user name (e.g. brad.pinter@gmail.com).
    -r --remote-user-name    remote ssh user name that will be associated with the key (e.g. galactus).
    -o --output-file         name of key pair (default: $OUTPUT_FILE).  NOTE: all keys are written in user's $HOME/.ssh directory.
    -e --expire-days         number of days the ssh key is valid with google cloud (default: 30).
    -f --force               force overwrite key pair if it already exists (USE WITH CAUTION!!!)
    -h --help                show this help


  Examples:
    $PROGNAME --user pinterb --account-name brad.pinter@gmail.com --remote-user-name galactus --expire-days $EXPIRE_DAYS --output-file $OUTPUT_FILE
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
      --user)              args="${args}-u ";;
      --account-name)      args="${args}-a ";;
      --remote-user-name)  args="${args}-r ";;
      --output-file)       args="${args}-o ";;
      --expire-days)       args="${args}-e ";;
      --force)             args="${args}-f ";;
      --help)              args="${args}-h ";;
      #pass through anything else
      *) [[ "${arg:0:1}" == "-" ]] || delim="\""
          args="${args}${delim}${arg}${delim} ";;
    esac
  done

  #Reset the positional parameters to the short options
  eval set -- $args

  while getopts ":u:a:r:o:e:fh" OPTION
  do
     case $OPTION in
     u)
         DEV_USER=$OPTARG
         ;;
     a)
         GCLOUD_USERNAME=$OPTARG
         ;;
     r)
         REMOTE_SSH_USER=$OPTARG
         ;;
     o)
         OUTPUT_FILE=$OPTARG
         ;;
     e)
         EXPIRE_DAYS=$OPTARG
         ;;
     f)
         readonly FORCE_OVERWRITE=1
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

  if [ -f "/home/$DEV_USER/.ssh/$OUTPUT_FILE" ]; then
    if [ -z "$FORCE_OVERWRITE" ]; then
      error "ssh key already exists.  Use the --force option if you want to overwrite.  But use with caution!"
      echo  ""
      usage
      exit 1
    fi
  fi
}


# Make sure we have all the right stuff
prerequisites() {
  local sshkeygen_cmd=`which ssh-keygen`

  if [ -z "$sshkeygen_cmd" ]; then
    error "ssh-keygen does not appear to be installed. Please install and re-run this script."
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
  local expir_date=$(date -d "+$EXPIRE_DAYS days" --utc --iso-8601='seconds')
#  su -c "ssh-keygen -b 2048 -t rsa -f ~/.ssh/google_compute_engine -C $DEV_USER -q -N \"\"" $DEV_USER
#  sed -i -e 's@pinterb@google-ssh {"userName":"pinterb","expireOn":"###EXPIRDT###"}@' ~/.ssh/google_compute_engine.pub
#  sed -i -e "s@###EXPIRDT###@${EXPIR_DT}@"  ~/.ssh/google_compute_engine.pub
#  sed -i -e "s@ssh-rsa@pinterb:ssh-rsa@" ~/.ssh/google_compute_engine.pub
#  su -c "chmod 400 ~/.ssh/google_compute_engine" pinterb





  su -c "mkdir -p /home/$DEV_USER/.ssh" "$DEV_USER"
  su -c "chmod 0700 /home/$DEV_USER/.ssh" "$DEV_USER"

  if [ -f "/home/$DEV_USER/.ssh/$OUTPUT_FILE" ]; then
    inf "ssh key already exists."

    # overwrite
    if [ -n "$FORCE_OVERWRITE" ]; then
      inf "forced overwrite of ssh key (type rsa) for $DEV_USER"
      su -c "ssh-keygen -b 2048 -t rsa -f /home/$DEV_USER/.ssh/$OUTPUT_FILE -C GCLOUDUSER -q -N \"\"" $DEV_USER
    fi
  else
    inf "creating a ssh key (type rsa) for $DEV_USER"
    su -c "ssh-keygen -b 2048 -t rsa -f /home/$DEV_USER/.ssh/$OUTPUT_FILE -C GCLOUDUSER -q -N \"\"" $DEV_USER
  fi

  su -c "cp /home/$DEV_USER/.ssh/${OUTPUT_FILE}.pub /home/$DEV_USER/.ssh/${OUTPUT_FILE}.pub.gcloudupload" "$DEV_USER"
  sed -i -e 's@GCLOUDUSER@###GUSER###@' "/home/$DEV_USER/.ssh/${OUTPUT_FILE}.pub"
  sed -i -e 's@GCLOUDUSER@google-ssh {"userName":"###GUSER###","expireOn":"###EXPIRDT###"}@' "/home/$DEV_USER/.ssh/${OUTPUT_FILE}.pub.gcloudupload"

  sed -i "s/###GUSER###/${GCLOUD_USERNAME}/" "/home/$DEV_USER/.ssh/${OUTPUT_FILE}.pub.gcloudupload"
  sed -i -e "s@###EXPIRDT###@${expir_date}@" "/home/$DEV_USER/.ssh/${OUTPUT_FILE}.pub.gcloudupload"
  sed -i -e "s@ssh-rsa@$REMOTE_SSH_USER:ssh-rsa@" "/home/$DEV_USER/.ssh/${OUTPUT_FILE}.pub.gcloudupload"

  sed -i "s/###GUSER###/${REMOTE_SSH_USER}/" "/home/$DEV_USER/.ssh/${OUTPUT_FILE}.pub"

  su -c "chmod 0600 /home/$DEV_USER/.ssh/${OUTPUT_FILE}" "$DEV_USER"
  su -c "chmod 0600 /home/$DEV_USER/.ssh/${OUTPUT_FILE}.pub" "$DEV_USER"
}


main() {
  # Be unforgiving about errors
  set -euo pipefail
  readonly SELF="$(absolute_path $0)"
  cmdline $ARGS
  valid_args
  prerequisites
  base_setup
}

[[ "$0" == "$BASH_SOURCE" ]] && main