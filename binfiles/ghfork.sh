#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"
readonly DEFAULT_PROGDIR=/home/pinter/projects/github
readonly DEFAULT_GH_USERNAME=pinterb
readonly CURL_CMD=`which curl`
readonly JQ_CMD=`which jq`
readonly GIT_CMD=`which git`

readonly GH_API_BASE_URI=https://api.github.com

declare -r TRUE=0
declare -r FALSE=1

# Get to where we need to be.
cd $PROGDIR

# Globals overridden as command line arguments
PROJECT_DIRECTORY=$DEFAULT_PROGDIR
GH_USER=$DEFAULT_GH_USERNAME

usage()
{
  echo -e "\033[33mHere's how to fork a GitHub repo and clone it (locally):"
  echo ""
  echo -e "\033[33m./$PROGNAME"
  echo -e "\t\033[33m-h --help"
  echo -e "\t\033[33m--repo=https://github.com/accountname/reponame (i.e. the url to the GitHub repository)"
  echo -e "\t\033[33m--user=$GH_USER (i.e. GitHub username)"
  echo -e "\t\033[33m--dir=$PROJECT_DIRECTORY (i.e. directory the forked repository will be cloned into)"
  echo -e "\033[0m"
}


parse_args()
{
  while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
      -h | --help)
        usage
        exit
        ;;
      --repo)
        REPO_URL=$VALUE
        ;;
      --user)
        GH_USER=$VALUE
        ;;
      --dir)
        PROJECT_DIRECTORY=$VALUE
        ;;
      *)
        echo -e "\033[31mERROR: unknown parameter \"$PARAM\""
        echo -e "\e[0m"
        usage
        exit 1
        ;;
    esac
    shift
  done

}


parse_repo_url()
{

  local  __repo_url=$REPO_URL
  local repo_owner=`echo $__repo_url | awk  -F / '{print $4}'`
  local repo_git=`echo $__repo_url | awk  -F / '{print $5}'`
  local repo_name=`echo $repo_git | awk  -F . '{print $1}'`
  local repo_param=$repo_owner/$repo_name
  echo $repo_param
}


valid_args()
{

  # Check for required params
  if [[ -z "$REPO_URL" ]]; then
    echo -e "\033[31mERROR: a repo name is required"
    echo -e "\e[0m"
    usage
    exit 1
  fi

  if [ ! -d "$PROJECT_DIRECTORY" ]; then
    echo -e "\033[31mERROR: directory \"$PROJECT_DIRECTORY\" does not exist"
    echo -e "\e[0m"
    usage
    exit 1
  fi

  local repo_name=$(parse_repo_url)
  local repo_subdir=`echo $repo_name | awk  -F / '{print $2}'`
  if [ -d "$PROJECT_DIRECTORY/$repo_subdir" ]; then
    echo -e "\033[31mERROR: clone directory \"$PROJECT_DIRECTORY/$repo_subdir\" already exists"
    echo -e "\e[0m"
    usage
    exit 1
  fi

}


valid_repo()
{

  local  __repo_param=$(parse_repo_url)
  local servername="$GH_API_BASE_URI/repos/$__repo_param/collaborators"
  local response=$($CURL_CMD -u "$GH_USER" --write-out %{http_code} --silent --output /dev/null $servername)

  if [[ "$response" == "404" ]]; then
    echo -e "\033[31mERROR: the GitHub repository url \"$REPO_URL\" is not valid."
    echo -e "\e[0m"
    usage
    exit 1
  fi
}



github_authenticate()
{
  my_curl_cmd="$CURL_CMD -u "$GH_USER" https://api.github.com"
  #response=$($CURL_CMD -u "$GH_USER" -s -o /dev/null -w '%{http_code}' https://api.github.com)
  ####response=$($CURL_CMD -u "$GH_USER" --write-out %{http_code} --silent --output /dev/null https://api.github.com)
  ####echo $response
  #curl -i https://api.github.com/repos/wolfeidau/usage/collaborators
  repo_owner=`echo $REPO_NAME | awk  -F / '{print $4}'`
  repo_git=`echo $REPO_NAME | awk  -F / '{print $5}'`
  repo_name=`echo $repo_git | awk  -F . '{print $1}'`
  repo_param=$repo_owner/$repo_name
  echo $repo_param
  exit
}

github_fork()
{

  local  __repo_param=$(parse_repo_url)
  local servername="$GH_API_BASE_URI/repos/$__repo_param/forks"
  local response=$($CURL_CMD -X POST -u "$GH_USER" --write-out %{http_code} --silent --output /dev/null $servername)

  if [[ ! "$response" == "202" ]]; then
    echo -e "\033[31mERROR: Attempted to fork repo. Expecting a return code of 202.  Instead received $response"
    echo -e "\e[0m"
    usage
    exit 1
  fi
  
  # The GitHub fork command is async.  So wait a few seconds for it to complete.
  sleep 15
}


clone_repo()
{
  local repo=$(parse_repo_url)
  local repo_name=`echo $repo | awk  -F / '{print $2}'`
  local clone_cmnd="$GIT_CMD clone https://github.com/$GH_USER/$repo_name.git"
  cd $PROJECT_DIRECTORY && $clone_cmnd
  
  if [ ! -d "$PROJECT_DIRECTORY/$repo_name" ]; then
    echo -e "\033[31mERROR: Attempted repo clone.  But clone directory \"$PROJECT_DIRECTORY/$repo_name\" does not exist"
    echo -e "\e[0m"
    usage
    exit 1
  fi
  
  local remote_name=`echo $repo | awk  -F / '{print $1}'`
  ##local remote_cmd="$GIT_CMD remote add --track master $remote_name https://github.com/$remote_name/$repo_name.git"
  ##local fetch_cmd="$GIT_CMD fetch $remote_name"
  ##local merge_cmd="$GIT_CMD merge $remote_name/master"
  local remote_cmd="$GIT_CMD remote add --track master upstream https://github.com/$remote_name/$repo_name.git"
  local fetch_cmd="$GIT_CMD fetch upstream"
  local merge_cmd="$GIT_CMD merge upstream/master"
  cd $PROJECT_DIRECTORY/$repo_name && $remote_cmd && $fetch_cmd && $merge_cmd
  
  echo "### " >> .git/config
  echo "# System-generated alias." >> .git/config
  echo "# These are some commands to make working with our upstream remote a bit easier" >> .git/config
  echo "# Please refer to http://gitready.com/intermediate/2009/02/12/easily-fetching-upstream-changes.html" >> .git/config
  echo "### " >> .git/config
  git config alias.pu '!git fetch origin -v; git fetch upstream -v; git merge upstream/master'
  git config alias.fa '!git remote | xargs -r -l1 git fetch && [ -d .git/svn ] && git-svn fetch || :'
  git config alias.pa '!git remote | xargs -r -l1 git push'
  git config alias.padry '!git remote | xargs -r -l1 git push --dry-run'

}


main()
{
  # Perform sanity check on command line arguments
  valid_args

  # Validate repo url against GitHub API
  valid_repo

  # Fork GitHub repo 
  github_fork

  # Finally, clone forked repo 
  clone_repo

}


parse_args "$@"
main
