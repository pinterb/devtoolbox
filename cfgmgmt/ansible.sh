
# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

### ansible
# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab
# http://docs.ansible.com/ansible/intro_installation.html#latest-releases-via-pip
###


install_ansible()
{
  echo ""
  hdr "Installing Ansible..."
  echo ""

  local install=0

  if command_exists ansible; then
    #local version="$(ansible --version | awk '{ print $2; exit }')"
    if [ $(ansible --version | awk '{ print $2; exit }') == "${ANSIBLE_VER}" ]; then
      warn "ansible is already installed"
      install=2
    else
      inf "ansible is already installed...but versions don't match"
      install=1
      exec_cmd 'pip install cryptography --upgrade'
      exec_cmd 'pip install git+git://github.com/ansible/ansible.git@devel --upgrade'
      exec_cmd 'pip install ansible-lint --upgrade'
      mark_as_installed ansible
    fi
  fi

  if [ $install -eq 0 ]; then
    exec_cmd 'pip install git+git://github.com/ansible/ansible.git@devel'
    exec_cmd 'pip install ansible-lint'
    mark_as_installed ansible
  fi
}


uninstall_ansible()
{
  echo ""
  hdr "Uninstalling Ansible..."
  echo ""

  if command_exists ansible; then
    exec_cmd 'pip uninstall -y ansible >/dev/null 2>&1'
    mark_as_uninstalled ansible
  else
      warn "ansible is not installed"
  fi

  if command_exists ansible-lint; then
    exec_cmd 'pip uninstall -y ansible-lint >/dev/null 2>&1'
  fi
}


