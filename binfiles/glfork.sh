#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"
readonly DEFAULT_PROGDIR=/home/pinter/projects/gl
readonly DEFAULT_GL_USERNAME=bpinter
readonly CURL_CMD=`which curl`
readonly JQ_CMD=`which jq`
readonly GIT_CMD=`which git`

readonly GL_HOST="gitlab.mgmt.arms-dev.net"
readonly GL_BASE_URI="https://$GL_HOST"
readonly GL_API_BASE_URI="$GL_BASE_URI/api/v4"
readonly GL_API_TOKEN="GsJs_7ucZTQidCgRtd7s"

# curl -q --header "Private-Token: GsJs_7ucZTQidCgRtd7s" https://gitlab.mgmt.arms-dev.net/api/v4/groups?search=infrastructure | jq .[0].id

declare -r TRUE=0
declare -r FALSE=1

# Get to where we need to be.
cd $PROGDIR

# Globals overridden as command line arguments
PROJECT_DIRECTORY=$DEFAULT_PROGDIR
GL_USER=$DEFAULT_GL_USERNAME

GL_PROJECT=

usage()
{
  echo -e "\033[33mHere's how to fork a GitLab repo and clone it (locally):"
  echo ""
  echo -e "\033[33m./$PROGNAME"
  echo -e "\t\033[33m-h --help"
  echo -e "\t\033[33m--repo=$GL_BASE_URI/groupname/reponame (i.e. the url to the GitLab repository)"
  echo -e "\t\033[33m--user=$GL_USER (i.e. GitLab username)"
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
        GL_USER=$VALUE
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
  local gl_group=`echo $__repo_param | awk -F / '{print $1}'`
  local gl_project=`echo $__repo_param | awk -F / '{print $2}'`

  local group_search="$GL_API_BASE_URI/groups?search=$gl_group"
  local response=$($CURL_CMD --header "Private-Token: $GL_API_TOKEN" --write-out %{http_code} --silent --output /dev/null $group_search)

  if [[ "$response" == "404" ]]; then
    echo -e "\033[31mERROR: the GitLab groups url \"$group_search\" is not valid."
    echo -e "\e[0m"
    usage
    exit 1
  fi

  local groups=$($CURL_CMD --silent --header "Private-Token: $GL_API_TOKEN" $group_search)
  local grp_len=$(echo $groups | jq length)
  if [[ "$grp_len" == "0" ]]; then
    echo -e "\033[31mERROR: the GitLab groups url \"$group_search\" returned nothing."
    echo -e "\e[0m"
    usage
    exit 1
  fi

  local group_id=$(echo $groups | jq .[0].id)
  if [ -z "$group_id" ]; then
    echo -e "\033[31mERROR: the GitLab groups url \"$group_search\" is not valid."
    echo -e "\e[0m"
    usage
    exit 1
  fi

  local project_search="$GL_API_BASE_URI/groups/$group_id/projects?search=$gl_project"
  local projects=$($CURL_CMD --silent --header "Private-Token: $GL_API_TOKEN" $project_search)
  local proj_len=$(echo $projects | jq length)
  if [[ "$proj_len" == "0" ]]; then
    echo -e "\033[31mERROR: the GitLab project search url \"$project_search\" returned nothing."
    echo -e "\e[0m"
    usage
    exit 1
  fi

  if [[ "$proj_len" != "1" ]]; then
    echo -e "\033[31mERROR: the GitLab project search url \"$project_search\" returned unexpected results."
    echo -e "\e[0m"
    usage
    exit 1
  fi


  local project_id=$(echo $projects | jq .[0].id)
  if [ -z "$project_id" ]; then
    echo -e "\033[31mERROR: the GitLab project search url \"$project_search\" is not valid."
    echo -e "\e[0m"
    usage
    exit 1
  fi

  GL_PROJECT=$project_id
}



github_authenticate()
{
  my_curl_cmd="$CURL_CMD -u "$GL_USER" https://api.github.com"
  #response=$($CURL_CMD -u "$GL_USER" -s -o /dev/null -w '%{http_code}' https://api.github.com)
  ####response=$($CURL_CMD -u "$GL_USER" --write-out %{http_code} --silent --output /dev/null https://api.github.com)
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
  local servername="$GL_API_BASE_URI/repos/$__repo_param/forks"
  local response=$($CURL_CMD -X POST -u "$GL_USER" --write-out %{http_code} --silent --output /dev/null $servername)

  if [[ ! "$response" == "202" ]]; then
    echo -e "\033[31mERROR: Attempted to fork repo. Expecting a return code of 202.  Instead received $response"
    echo -e "\e[0m"
    usage
    exit 1
  fi

  # The GitLab fork command is async.  So wait a few seconds for it to complete.
  sleep 15
}


gitlab_fork()
{

  local servername="$GL_API_BASE_URI/projects/$GL_PROJECT/fork"
  local response=$($CURL_CMD -X POST --header "Private-Token: $GL_API_TOKEN" --write-out %{http_code} --silent --output /dev/null $servername)

  if [[ "$response" == "409" ]]; then
    echo -e "\033[31mWARN: Attempted to fork gitlab project. But it appears it might already be forked"
    echo -e "\e[0m"
  elif [[ ! "$response" == "201" ]]; then
    echo -e "\033[31mERROR: Attempted to fork gitlab project. Expecting a return code of 201.  Instead received $response"
    echo -e "\e[0m"
    usage
    exit 1
  fi

  # The GitLab fork command is async.  So wait a few seconds for it to complete.
  sleep 15
}


clone_repo()
{
  local repo=$(parse_repo_url)
  local repo_name=`echo $repo | awk  -F / '{print $2}'`
  local clone_cmnd="$GIT_CMD clone https://github.com/$GL_USER/$repo_name.git"
  local clone_cmnd="$GIT_CMD clone ssh://git@$GL_HOST:2222/$GL_USER/$repo_name.git"
  cd $PROJECT_DIRECTORY && $clone_cmnd

  if [ ! -d "$PROJECT_DIRECTORY/$repo_name" ]; then
    echo -e "\033[31mERROR: Attempted repo clone.  But clone directory \"$PROJECT_DIRECTORY/$repo_name\" does not exist"
    echo -e "\e[0m"
    usage
    exit 1
  fi

  local remote_name=`echo $repo | awk  -F / '{print $1}'`
  local remote_cmd="$GIT_CMD remote add --track master upstream ssh://git@$GL_HOST:2222/$remote_name/$repo_name.git"
  local fetch_cmd="$GIT_CMD fetch upstream"
  local merge_cmd="$GIT_CMD merge upstream/master"
  cd $PROJECT_DIRECTORY/$repo_name && $remote_cmd && $fetch_cmd && $merge_cmd

  echo "###" >> .git/config
  echo "# System-generated alias." >> .git/config
  echo "# These are some commands to make working with our upstream remote a bit easier" >> .git/config
  echo "# Please refer to http://gitready.com/intermediate/2009/02/12/easily-fetching-upstream-changes.html" >> .git/config
  echo "###" >> .git/config
  git config alias.pu '!git fetch origin -v; git fetch upstream -v; git merge upstream/master'
  git config alias.fa '!git remote | xargs -r -l1 git fetch && [ -d .git/svn ] && git-svn fetch || :'
  git config alias.pa '!git remote | xargs -r -l1 git push'
  git config alias.padry '!git remote | xargs -r -l1 git push --dry-run'

}


main()
{
  # Perform sanity check on command line arguments
  valid_args

  # Validate repo url against GitLab API
  valid_repo

  # Fork GitLab repo
  gitlab_fork

  # Finally, clone forked repo
  clone_repo

}


parse_args "$@"
main
