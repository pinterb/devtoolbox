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
source "$PROGDIR/golang_profile"

# third-party go
readonly GLIDE_VERSION="0.11.0"
readonly GODEP_VERSION="74"

# cli arguments
INSTALL_GOLANG=


usage() {
  cat <<- EOF
  usage: $PROGNAME options

  $PROGNAME bootstraps all or some of a development environment for a new, non-privileged user.
  It downloads install scripts under the new user's home directory and enables .profile or .bash_profile
  to install specified development tools.

  OPTIONS:
    -i --install             install golang
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
         readonly INSTALL_GOLANG=1
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
  if [ ! -d "$GOPROJECTS_HOME" ]; then
    echo ""
    inf "Creating $GOPROJECTS_HOME/{src,bin,pkg}"
    mkdir -p "$GOPROJECTS_HOME"/{src,bin,pkg}
    mkdir -p "$GOPROJECTS_HOME/src/github.com"
  fi

  inf "Setting up profile"
  cp "$PROGDIR/golang_profile" $HOME/.golang_profile

  echo ""
  if [ -f "$HOME/.bash_profile" ]; then
    inf "Setting up .bash_profile"
    grep -q -F 'source "$HOME/.golang_profile"' "$HOME/.bash_profile" || echo 'source "$HOME/.golang_profile"' >> "$HOME/.bash_profile"
  else
    inf "Setting up .profile"
    grep -q -F 'source "$HOME/.golang_profile"' "$HOME/.profile" || echo 'source "$HOME/.golang_profile"' >> "$HOME/.profile"
  fi
}


install_golang()
{
  inf ""
  inf "installing golang..."

  rm -rf "$DOWNLOAD_DIR/install-golang"
  git clone https://github.com/pinterb/install-golang.sh "$DOWNLOAD_DIR/install-golang"
  cd "$DOWNLOAD_DIR/install-golang" || exit 1
  sudo ./install-golang.sh
}


install_glide() {
  readonly glide_url="https://github.com/Masterminds/glide/releases/download/v$GLIDE_VERSION/glide-v$GLIDE_VERSION-linux-amd64.tar.gz"

  echo ""
  inf "Installing Glide"
  curl -Lo "$DOWNLOAD_DIR/glide.tar.gz" "$glide_url"
  cd $DOWNLOAD_DIR && tar -xvf $DOWNLOAD_DIR/glide.tar.gz
  chmod +x "$DOWNLOAD_DIR/linux-amd64/glide"
  mv "$DOWNLOAD_DIR/linux-amd64/glide" $HOME/bin/
  chmod +x $HOME/bin/glide
  rm "$DOWNLOAD_DIR/glide.tar.gz"
  rm -rf "$DOWNLOAD_DIR/linux-amd64"
}


install_godep() {
  readonly godep_url="https://github.com/tools/godep/releases/download/v$GODEP_VERSION/godep_linux_amd64"

  echo ""
  inf "Installing godep"
  curl -Lo "$HOME/bin/godep" "$godep_url"
  chmod +x "$HOME/bin/godep"
}


install_go_swagger() {
  echo ""
  inf "Installing go-swagger"
  latestv=$(curl -s https://api.github.com/repos/go-swagger/go-swagger/releases/latest | jq -r .tag_name)
  curl -o $HOME/bin/swagger -L'#' https://github.com/go-swagger/go-swagger/releases/download/$latestv/swagger_$(echo `uname`|tr '[:upper:]' '[:lower:]')_amd64
  chmod +x $HOME/bin/swagger
}


install_go_gettables() {
  local go_root="/usr/local/go"
  ###
  # cobra
  ###
  readonly cobra_url="github.com/spf13/cobra/cobra"
  echo ""
  inf "Installing cobra"
  $go_root/bin/go get -u "$cobra_url"
  cp "$PROGDIR/cobra.yaml" "$HOME/.cobra.yaml"

  ###
  # interfacer
  ###
  readonly interfacer_url="github.com/mvdan/interfacer/cmd/interfacer"
  echo ""
  inf "Installing interfacer"
  $go_root/bin/go get -u "$interfacer_url"


  ###
  # depscheck
  ###
  readonly depscheck_url="github.com/divan/depscheck"
  echo ""
  inf "Installing depscheck"
  $go_root/bin/go get -u "$depscheck_url"


  ###
  # gosimple
  ###
  readonly gosimple_url="honnef.co/go/simple/cmd/gosimple"
  echo ""
  inf "Installing gosimple"
  $go_root/bin/go get -u "$gosimple_url"
  

  ###
  # sqlboiler
  ###
  readonly sqlboiler_url="github.com/vattle/sqlboiler"
  echo ""
  inf "Installing sqlboiler"
  $go_root/bin/go get -u -t "$sqlboiler_url"
  
  
  ###
  # go-interface-fuzzer
  ###
  readonly interface_fuzzer_url="github.com/pusher/go-interface-fuzzer"
  echo ""
  inf "Installing interface-fuzzer"
  $go_root/bin/go get -u -t "$interface_fuzzer_url"
  
  
  ###
  # openapi2proto
  ###
  readonly openapi2proto_url="github.com/NYTimes/openapi2proto/cmd/openapi2proto"
  echo ""
  inf "Installing openapi2proto"
  $go_root/bin/go get -u "$openapi2proto_url"

  
  ###
  # grpc
  ###
  readonly grpc_url="google.golang.org/grpc"
  echo ""
  inf "Installing grpc"
  $go_root/bin/go get -u "$grpc_url"

  
  ###
  # protobuf
  ###
  readonly protobuf_url="github.com/golang/protobuf/{proto,protoc-gen-go}"
  echo ""
  inf "Installing protobuf"
  $go_root/bin/go get -u "$protobuf_url"

  
  ###
  # lego 
  ###
  readonly lego_url="github.com/xenolf/lego"
  echo ""
  inf "Installing lego"
  $go_root/bin/go get -u "$lego_url"


  ###
  # lint
  ###
  readonly lint_url="github.com/golang/lint/golint"
  echo ""
  inf "Installing lint"
  $go_root/bin/go get -u "$lint_url"
}


main() {
  # Be unforgiving about errors
  set -euo pipefail
  cmdline $ARGS
  prerequisites
  local_setup

  # golang handler
  if [ -n "$INSTALL_GOLANG" ]; then
    install_golang
  fi

  install_glide
  install_godep
  install_go_gettables
}

[[ "$0" == "$BASH_SOURCE" ]] && main
