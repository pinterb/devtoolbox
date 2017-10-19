#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"
readonly NPM_CMD=`which npm`
readonly CODENAME_CMD=`which codename`

readonly GH_API_BASE_URI=https://api.github.com

declare -r TRUE=0
declare -r FALSE=1

# Get to where we need to be.
cd $PROGDIR

if [ -z "$NPM_CMD" ]; then
  echo "it doesn't look like node.js is installed."
  echo "  install node.js first; and then try this again"
  exit 1
fi

if [ -z "$CODENAME_CMD" ]; then
  sudo npm install --global intel-codenames-picker >/dev/null
fi

codename --slug
