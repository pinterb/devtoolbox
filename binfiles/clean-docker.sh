#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

readonly PROGNAME=$(basename "$0")
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

warn() {
  echo -e "\033[1;33mWARNING: $1\033[0m"
}

error() {
  echo -e "\033[0;31mERROR: $1\033[0m"
}

inf() {
  echo -e "\033[0;32m$1\033[0m"
}

# Make sure we have all the right stuff
prerequisites() {
  if ! command_exists docker; then
    error "Docker doesn't appear to be installed.  Verify that Docker is installed and try again."
  fi
}

remove_stopped() {
  echo ""
  inf "Removing all stopped containers..."
  echo ""
  for i in $(docker ps --no-trunc -a -q);do docker rm "$i";done
}

remove_untagged() {
  echo ""
  inf "Removing all untagged images..."
  echo ""
  docker images --no-trunc | grep none | awk '{print $$3}' | xargs -r docker rmi
}

main() {
  # Be unforgiving about errors
  set -euo pipefail
  prerequisites
  remove_stopped
  remove_untagged  
}

[[ "$0" == "$BASH_SOURCE" ]] && main

