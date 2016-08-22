#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"

if [ -f "$PROGDIR/userns.conf" ]; then
  cd "$PROGDIR" || exit 1
  mkdir -p /etc/systemd/system/docker.service.d
  cp "$PROGDIR/userns.conf" /etc/systemd/system/docker.service.d/
  sed -i -e "s@###DOCKER_USER_NAMESPACE###@${1}@" /etc/systemd/system/docker.service.d/userns.conf

  readonly DEV_SUB_UID=$(id -u $1)
  readonly DEV_SUB_GID=$(id -g $1)

  grep -q -F "$1" "/etc/subuid" || echo "$1:$DEV_SUB_UID:1" >> "/etc/subuid"
  grep -q -F "$1" "/etc/subgid" || echo "$1:$DEV_SUB_GID:1" >> "/etc/subgid"

fi
