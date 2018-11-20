#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"

if [ -z $1 ]; then
  echo "you must enter a zone, for example:"
  echo "  $PROGNAME us-central1-c"
  echo ""
  echo "NOTE: if you need a list of GCP zones; run gcp-zones.sh"
  exit
fi

gcloud container get-server-config --zone $1

