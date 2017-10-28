#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"
readonly ARGS="$@"
readonly TODAY=$(date +%Y%m%d%H%M%S)

# pull in utils
source "${PROGDIR}/utils.sh"

cd $PROGDIR && cd ..
if [[ -d "keybase-cloudcreds" ]]; then
  cd keybase-cloudcreds
  git_url=$(git config --get remote.origin.url)
  if [ "$git_url" == 'keybase://private/pinterb/cloudcreds' ]; then
    inf "Looks like we're in the correct directory"
    git pull
  else
    error "Expecting to find keybase cloud creds git config."
    exit 1
  fi
else
  git clone keybase://private/pinterb/cloudcreds keybase-cloudcreds
  cd keybase-cloudcreds
  if [ "$git_url" == 'keybase://private/pinterb/cloudcreds' ]; then
    inf "Looks like we're in the correct directory"
  else
    error "Expecting to find keybase cloud creds git config."
    exit 1
  fi
fi

if [[ -f "extra" && -f "setup.sh" ]]; then
  sh setup.sh
else
  error "Hmmm...expecting keybase cloud creds to install."
  error "...But not finding expected script(s).  Not sure we're inside correct directory."
  exit 1
fi

