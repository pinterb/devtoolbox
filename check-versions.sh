#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

# http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"
readonly ARGS="$@"
readonly TODAY=$(date +%Y%m%d%H%M%S)

# pull in utils
source "${PROGDIR}/utils.sh"

if ! command_exists curl; then
  warn "curl doesn't appear to be installed."
  exit 0
fi

if ! command_exists jq; then
  warn "jq doesn't appear to be installed."
  exit 0
fi

compare() {
  local desc=$1
  local url=$2
  local old=$3

  local new=
  if [[ $url == http* ]]; then
    new=$(curl --silent "$url" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' || "meh?")
  else
    new=$url
  fi

  # if using jq, the new version value may be wrapped in quotes
  temp="${new%\"}"
  temp="${new#\"}"

  if [ "$old" != "$new" ]; then
    inf "$desc: Using $old; $new is available"
  fi
}

## https://github.com/azure/draft
compare "draft" \
  "https://api.github.com/repos/azure/draft/releases/latest" \
  "$DRAFT_VER"

## https://github.com/google/protobuf
compare "protobuf" \
  "https://api.github.com/repos/google/protobuf/releases/latest" \
  "$PROTOBUF_VER"

## https://github.com/uber/prototool
compare "prototool" \
  "https://api.github.com/repos/uber/prototool/releases/latest" \
  "$PROTOTOOL_VER"

## https://github.com/apex/up
compare "up" \
  "https://api.github.com/repos/apex/up/releases/latest" \
  "$UP_VER"

#GOLANG_NEW_VER="1.10"

## https://github.com/kubernetes/helm
compare "helm" \
  "https://api.github.com/repos/kubernetes/helm/releases/latest" \
  "$HELM_VER"

## https://github.com/kubernetes/minikube
compare "minikube" \
  "https://api.github.com/repos/kubernetes/minikube/releases/latest" \
  "$MINIKUBE_VER"

## https://github.com/hashicorp/terraform
compare "terraform" \
  "https://api.github.com/repos/hashicorp/terraform/releases/latest" \
  "$TERRAFORM_VER"

## https://github.com/cloudflare/cfssl
compare "cfssl" \
  "https://api.github.com/repos/cloudflare/cfssl/releases/latest" \
  "$CFSSL_VER"

## https://github.com/kubernetes/kops
compare "kops" \
  "https://api.github.com/repos/kubernetes/kops/releases/latest" \
  "$KOPS_VER"

## https://github.com/kubernetes/kubernetes
compare "kubernetes" \
  "$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)" \
  "$KUBE_VER"

## https://github.com/digitalocean/doctl
compare "doctl" \
  "https://api.github.com/repos/digitalocean/doctl/releases/latest" \
  "$DOCTL_VER"

#DOCKER_NEW_VER="17.03.2" # this version is compatiable w/k8s v1.9
#HABITAT_NEW_VER="0.54.0"
#HABITAT_NEW_VER_TS="20180221022026"

## https://github.com/ansible/ansible/releases
compare "ansible" \
  "https://api.github.com/repos/ansible/ansible/releases/latest" \
  "$ANSIBLE_VER"

## https://github.com/Azure/azure-cli
compare "azure" \
  "https://api.github.com/repos/Azure/azure-cli/releases/latest" \
  "$AZURE_VER"

#NGROK_NEW_VER="2.2.6"
#
### 
#compare "jfrog" \
#  "https://api.github.com/repos/JFrogDev/jfrog-cli-go/releases/latest" \
#  "$JFROG_VER"

## https://github.com/JFrogDev/jfrog-cli-go
compare "jfrog" \
  "https://api.github.com/repos/JFrogDev/jfrog-cli-go/releases/latest" \
  "$JFROG_VER"

## https://github.com/chef/inspec
compare "inspec" \
  "https://api.github.com/repos/chef/inspec/releases/latest" \
  "$INSPEC_VER"

## https://github.com/bazelbuild/bazel
compare "bazel" \
  "https://api.github.com/repos/bazelbuild/bazel/releases/latest" \
  "$BAZEL_VER"

## https://github.com/jenkins-x/jx
compare "jenkins-x" \
  "https://api.github.com/repos/jenkins-x/jx/releases/latest" \
  "$JENKINSX_VER"

## https://github.com/GoogleContainerTools/skaffold
compare "skaffold" \
  "https://api.github.com/repos/GoogleContainerTools/skaffold/releases/latest" \
  "$SKAFFOLD_VER"

## https://github.com/goreleaser/goreleaser
compare "goreleaser" \
  "https://api.github.com/repos/goreleaser/goreleaser/releases/latest" \
  "$GORELEASER_VER"


## https://github.com/fission/fission
compare "fission" \
  "https://api.github.com/repos/fission/fission/releases/latest" \
  "$FISSION_VER"

## https://github.com/bitnami-labs/sealed-secrets
compare "sealed-secrets" \
  "https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest" \
  "$K8S_SEALED_SECRETS_VER"

## https://github.com/rust-lang-nursery/rustup.rs
compare "rustup" \
  "https://api.github.com/repos/rust-lang-nursery/rustup.rs/releases/latest" \
  "RUSTUP_VER"


