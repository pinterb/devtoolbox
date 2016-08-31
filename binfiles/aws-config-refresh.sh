#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"
EXTRAS_FILE=${EXTRAS_FILE:-"$HOME/.extra"}
AWS_CONFIG_DIR=${AWS_CONFIG_DIR:-"$HOME/.aws"}

if [ -f "$EXTRAS_FILE" ]; then
  source "$EXTRAS_FILE"

  if [ -f "$AWS_CONFIG_DIR/config.tpl" ]; then
    cp $AWS_CONFIG_DIR/config.tpl $AWS_CONFIG_DIR/config
    sed -i -e "s@###AWS_DEFAULT_REGION###@${AWS_DEFAULT_REGION}@" "$AWS_CONFIG_DIR/config"
  else
    echo "Missing the required '$AWS_CONFIG_DIR/config.tpl' file used to populate aws cli configuration."
  fi

  if [ -f "$AWS_CONFIG_DIR/credentials.tpl" ]; then
    cp $AWS_CONFIG_DIR/credentials.tpl $AWS_CONFIG_DIR/credentials
    sed -i -e "s@###AWS_ACCESS_KEY_ID###@${AWS_ACCESS_KEY_ID}@" "$AWS_CONFIG_DIR/credentials"
    sed -i -e "s@###AWS_SECRET_ACCESS_KEY###@${AWS_SECRET_ACCESS_KEY}@" "$AWS_CONFIG_DIR/credentials"
  else
    echo "Missing the required '$AWS_CONFIG_DIR/credentials.tpl' file used to populate aws cli configuration."
  fi

else
  echo "User '$USER' doesn't have the required '$EXTRAS_FILE' file used to populate aws cli configuration."
fi
