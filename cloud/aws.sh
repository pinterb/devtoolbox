### aws cli
# http://docs.aws.amazon.com/cli/latest/userguide/installing.html
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_aws()
{
  echo ""
  hdr "Installing AWS CLI..."
  echo ""

  local inst_dir="/home/$DEV_USER/.aws"

  mkdir -p "$inst_dir"
#  cp "$PROGDIR/aws/config.tpl" "$inst_dir/"
#  cp "$PROGDIR/aws/credentials.tpl" "$inst_dir/"

  if command_exists aws; then
    warn "aws cli is already installed...attempting upgrade"
    exec_cmd 'pip install --upgrade awscli'
  else
    exec_cmd 'pip install awscli'
    mark_as_installed awscli
  fi

  exec_cmd "chown -R $DEV_USER:$DEV_USER $inst_dir"
}


uninstall_aws()
{
  echo ""
  hdr "Uninstalling AWS CLI..."
  echo ""

  local inst_dir="/home/$DEV_USER/.aws"

  if command_exists aws; then
    exec_cmd 'pip uninstall -y awscli >/dev/null 2>&1'
  #  exec_cmd "rm -rf $inst_dir"
    mark_as_uninstalled awscli
  else
    warn "aws cli is not installed"
  fi
}

