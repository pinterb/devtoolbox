#!/bin/bash -

HELM_VER="2.0.0-alpha.4"
TERRAFORM_VER="0.9.2"
CFSSL_VER="1.2"
KUBE_VER="1.3.6"
PROTOBUF_VER="3.1.0"
KOPS_VER="1.5.3"
KUBE_AWS_VER="0.9.4-rc.2"
DOCTL_VER="1.5.0"

# Get distro data from /etc/os-release
if [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    DISTRO_ID=$DISTRIB_ID
    DISTRO_VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    DISTRO_ID=Debian
    DISTRO_VER=$(cat /etc/debian_version)
elif [ -f /etc/centos-release ]; then
    DISTRO_ID=$(awk '{print $1}' /etc/centos-release)
    DISTRO_VER=$(awk '{print $4}' /etc/centos-release)
elif [ -f /etc/redhat-release ]; then
    DISTRO_ID=RHEL
    DISTRO_VER=$(awk '{print $7}' /etc/redhat-release)
elif [ -f /etc/os-release ]; then
    DISTRO_ID=$(awk -F'=' '/NAME/ {print $2; exit}' /etc/os-release)
    DISTRO_VER=$(awk -F'=' '/VERSION_ID/ {print $2}' /etc/os-release | tr -d '"')
else
    DISTRO_ID=$(uname -s)
    DISTRO_VER=$(uname -r)
fi

readonly TRUE=0
readonly FALSE=1

readonly CLOUD_PROVIDER=$([ -f /sys/class/dmi/id/bios_vendor ] && cat /sys/class/dmi/id/bios_vendor)

# physical memory
readonly MEM_TOTAL_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')

# For non-privileged users, this may be our default user
DEFAULT_USER="$(id -un 2>/dev/null || true)"

warn() {
  echo -e "\033[1;33mWARNING: $1\033[0m"
}

error() {
  echo -e "\033[0;31mERROR: $1\033[0m"
}

inf() {
  echo -e "\033[0;32m$1\033[0m"
}

follow() {
  inf "Following docker logs now. Ctrl-C to cancel."
  docker logs --follow $1
}

run_command() {
  inf "Running:\n $1"
  eval $1 &> /dev/null
}

# Given a relative path, calculate the absolute path
absolute_path() {
  pushd "$(dirname $1)" > /dev/null
  local abspath="$(pwd -P)"
  popd > /dev/null
  echo "$abspath/$(basename $1)"
}

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

semverParse() {
  major="${1%%.*}"
  minor="${1#$major.}"
  minor="${minor%%.*}"
  patch="${1#$major.$minor.}"
  patch="${patch%%[-.]*}"
}
