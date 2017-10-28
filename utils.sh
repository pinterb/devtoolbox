
# SOFTWARE VERSIONS
# (Last Checked On: 2017-10-06)
DRAFT_VER="0.7.0"
PROTOBUF_VER="3.4.1"
UP_VER="0.2.6"
GOLANG_VER="1.9.2"
HELM_VER="2.6.2"
MINIKUBE_VER="0.22.2"
TERRAFORM_VER="0.10.7"
CFSSL_VER="1.2"
KOPS_VER="1.7.0"
KUBE_VER="1.8.0"
DOCTL_VER="1.7.0"
DOCKER_VER="17.09.0"
HABITAT_VER="0.34.1"
HABITAT_VER_TS="20171002002928"
ANSIBLE_VER="2.4.0"
AZURE_VER="2.0.12"
NGROK_VER="2.2.6"
JFROG_VER="1.10.1"

# https://cloud.google.com/sdk/downloads#versioned
GCLOUD_VER="174.0.0"
GCLOUD_CHECKSUM="b8e6520aa071d59b31d4477e81be5d240205c5307f6b0072765c827a7d969b58"

# https://bosh.io/docs/cli-v2#install
BOSH_VER="2.0.40"
BOSH_CHECKSUM="0045668aa6582ddd518cfb2b6134eba439bbb94d"

# Candidates for removal
KUBE_AWS_VER="0.9.7-rc.2"


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

# sys_arch discovers the architecture for this system.
sys_arch() {
  ARCH=$(uname -m)
  case $ARCH in
    armv5*) ARCH="armv5";;
    armv6*) ARCH="armv6";;
    armv7*) ARCH="armv7";;
    aarch64) ARCH="arm64";;
    x86) ARCH="386";;
    x86_64) ARCH="amd64";;
    i686) ARCH="386";;
    i386) ARCH="386";;
  esac
}

##
# determine if this script is running on a Microsoft WSL version of Linux
# https://stackoverflow.com/questions/38086185/how-to-check-if-a-program-is-run-in-bash-on-ubuntu-on-windows-and-not-just-plain
microsoft_wsl() {
  grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null
}

# For non-privileged users, this may be our default user
DEFAULT_USER="$(id -un 2>/dev/null || true)"

MYINDENT="  "
bump_indent() {
  MYINDENT="  $MYINDENT"
}

reset_indent() {
  MYINDENT="  "
}

set_indent() {
  MYINDENT="$1"
}

warn() {
  echo -e "\033[1;33m$MYINDENT+ WARNING: $1\033[0m"
}

error() {
  echo -e "\033[0;31m$MYINDENT+ ERROR: $1\033[0m"
}

inf() {
  echo -e "\033[0;32m$MYINDENT+ $1\033[0m"
}

cmd_inf() {
  echo -e "\033[0;32m$MYINDENT  ++ $1\033[0m"
}

hdr() {
  echo -e "\033[0;32m$1\033[0m"
  reset_indent
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

function_exists() {
  #type -t "$@" && type -t "$@" | grep -q '^function$' > /dev/null 2>&1
  if [[ $(type -t "$@" 2>/dev/null) == function ]]; then
    return 0
  else
    return 1
  fi
}

mark_dotprofile_as_touched() {
  if [ "$DEFAULT_USER" == 'root' ]; then
    su -c "mkdir -p /home/$DEV_USER/.bootstrap/touched-dotprofile" "$DEV_USER"
    su -c "echo 'modified by install script' > /home/$DEV_USER/.bootstrap/touched-dotprofile/$@" "$DEV_USER"
  else
    mkdir -p "/home/$DEV_USER/.bootstrap/touched-dotprofile"
    echo 'modified by install script' > "/home/$DEV_USER/.bootstrap/touched-dotprofile/$@"
  fi
}

is_backed_up() {
  local bkup="${1:-orig}"

  if [ -d "/home/$DEV_USER/.bootstrap/backup/$bkup" ]; then
    return 0
  else
    return 1
  fi
}

is_installed() {
  if [ ! -d "/home/$DEV_USER/.bootstrap/installed" ]; then
    return 1
  fi

  if [ -f "/home/$DEV_USER/.bootstrap/installed/$1" ]; then
    return 0
  else
    return 1
  fi
}

mark_as_installed() {

  if [ ! -d "/home/$DEV_USER/.bootstrap/installed" ]; then
   # if [ "$DEFAULT_USER" == 'root' ]; then
   #   su -c "mkdir -p /home/$DEV_USER/.bootstrap/installed" "$DEV_USER"
   # else
   #   bash -c "mkdir -p /home/$DEV_USER/.bootstrap/installed"
   # fi
    exec_cmd "mkdir -p /home/$DEV_USER/.bootstrap/installed"
  fi

  exec_cmd "touch /home/$DEV_USER/.bootstrap/installed/$1"
  exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER/.bootstrap/installed/$1"

#  if [ "$DEFAULT_USER" == 'root' ]; then
#    su -c "touch /home/$DEV_USER/.bootstrap/installed/$1" "$DEV_USER"
#  else
#    bash -c "touch /home/$DEV_USER/.bootstrap/installed/$1"
#  fi
}

mark_as_uninstalled() {
  exec_cmd "rm -rf /home/$DEV_USER/.bootstrap/installed/$1"
}

semverParse() {
  major="${1%%.*}"
  minor="${1#$major.}"
  minor="${minor%%.*}"
  patch="${1#$major.$minor.}"
  patch="${patch%%[-.]*}"
}
