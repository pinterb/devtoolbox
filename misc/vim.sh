
# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

##
# Base packages for building vim from source.
# NOTE: git, build-essential, cmake, python-dev, python3-dev are also required packages,
# but they are included as part of this bootstraps base package install.
VIM_NEW_BASE_PKGS="vim-nox"

VIM_OLD_PKGS="vim vim-runtime vim-tiny vim-common vim-gui-common"


install_vim()
{
  echo ""
  hdr "Install vim (from source)..."
  echo ""

  inf "installing base packages..."
  exec_cmd "apt-get install -yq --allow-unauthenticated $VIM_NEW_BASE_PKGS >/dev/null 2>&1"

  inf "removing existing vim packages..."
  exec_cmd "apt-get remove -yq $VIM_OLD_PKGS >/dev/null 2>&1"

  exec_cmd "rm -rf /usr/local/bin/vim /usr/bin/vim"
  exec_nonprv_cmd "git clone https://github.com/vim/vim /home/$DEV_USER/vim"

  pushd "/home/$DEV_USER/vim"
  pushd "src"
  ./configure \
    --with-features=huge \
    --enable-rubyinterp \
    --enable-pythoninterp \
    --with-python-config-dir=/usr/lib/python2.7-config \
    --enable-perlinterp \
    --enable-cscope --prefix=/usr

  exec_cmd "make install"
  popd
  exec_cmd "rm -rf /home/$DEV_USER/vim"

  mark_as_installed vimsrc
}


uninstall_vim()
{
  echo ""
  hdr "Uninstall vim (from source)..."
  echo ""

  exec_cmd "rm -rf /usr/local/bin/vim /usr/bin/vim"

  inf "removing new base packages..."
  exec_cmd "apt-get remove -yq $VIM_NEW_BASE_PKGS >/dev/null 2>&1"

  inf "re-install base vim packages..."
  exec_cmd "apt-get install -yq --allow-unauthenticated $VIM_OLD_PKGS >/dev/null 2>&1"

  mark_as_uninstalled vimsrc
}


install_vim_mods()
{
  echo ""
  hdr "Modify vim with colors and plugin mgr..."
  echo ""

  local inst_dir="/home/$DEV_USER/.vim"
  exec_cmd "mkdir -p $inst_dir/autoload $inst_dir/colors"

  ## not quite sure yet which vim plugin manager to use
  #  exec_cmd "curl -fLo $inst_dir/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  exec_cmd "curl -LSso $inst_dir/autoload/pathogen.vim https://tpo.pe/pathogen.vim"

  # some vim colors
  if [ -d "/home/$DEV_USER/projects/vim-colors-molokai" ]; then
    exec_cmd "cd /home/$DEV_USER/projects/vim-colors-molokai; git pull"
  else
    exec_cmd "git clone https://github.com/fatih/molokai /home/$DEV_USER/projects/vim-colors-molokai"
  fi

  if [ -f "/home/$DEV_USER/projects/vim-colors-molokai/colors/molokai.vim" ]; then
    exec_cmd "cp /home/$DEV_USER/projects/vim-colors-molokai/colors/molokai.vim $inst_dir/colors/molokai.vim"
  fi

  exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER"
  mark_as_installed vimmods
}


uninstall_vim_mods()
{
  echo ""
  hdr "Uninstall vim modifications incl. colors and plugin mgr..."
  echo ""

  local inst_dir="/home/$DEV_USER/.vim"

  if [ -f "$inst_dir/autoload/pathogen.vim" ]; then
    exec_cmd "rm $inst_dir/autoload/pathogen.vim"
  fi

  # some vim colors
  if [ -f "$inst_dir/colors/molokai.vim" ]; then
    exec_cmd "rm $inst_dir/colors/molokai.vim"
  fi

  if [ -d "/home/$DEV_USER/projects/vim-colors-molokai" ]; then
    exec_cmd "rm -rf /home/$DEV_USER/projects/vim-colors-molokai"
  fi

  exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER"
  mark_as_uninstalled vimmods
}


enable_pathogen_bundles()
{
  echo ""
  hdr "Enabling vim & pathogen bundles..."
  echo ""

  local inst_dir="/home/$DEV_USER/.vim/bundle"
  rm -rf "$inst_dir"; mkdir -p "$inst_dir"
  cd "$inst_dir" || exit 1

  inf "Re-populating pathogen bundles..."

  ## colors
  git clone git://github.com/altercation/vim-colors-solarized.git

  ## golang
  git clone https://github.com/fatih/vim-go.git

  ## json
  git clone https://github.com/elzr/vim-json.git

  ## yaml
  git clone https://github.com/avakhov/vim-yaml

  ## Ansible
  git clone https://github.com/pearofducks/ansible-vim

  ## Dockerfile
  git clone https://github.com/ekalinin/Dockerfile.vim.git \
  "$inst_dir/Dockerfile"

  ## Nerdtree
  git clone https://github.com/scrooloose/nerdtree.git

  ## Ruby
  git clone git://github.com/vim-ruby/vim-ruby.git

  ## Python
  git clone https://github.com/klen/python-mode.git

  ## Whitespace (hint: to see whitespace just :ToggleWhitespace)
  git clone git://github.com/ntpeters/vim-better-whitespace.git

  ## Git
  git clone http://github.com/tpope/vim-git

  ## Terraform
  git clone http://github.com/hashivim/vim-terraform

  ## gotests
  git clone https://github.com/buoto/gotests-vim

  if [ $MEM_TOTAL_KB -ge 1500000 ]; then
    enable_vim_ycm
    cd "$inst_dir"
  else
    warn "Your system requires at least 1.5 GB of memory to "
    warn "install the YouCompleteMe vim plugin. Skipping... "
  fi

  # handle .vimrc
  if [ -f "/home/$DEV_USER/.vimrc" ]; then
    inf "Backing up .vimrc file"
    cp "/home/$DEV_USER/.vimrc" "/home/$DEV_USER/.vimrc-$TODAY"
  fi

  if [ -f "$PROGDIR/dotfiles/vimrc" ]; then
    inf "Copying new .vimrc file"
    cp "$PROGDIR/dotfiles/vimrc" "/home/$DEV_USER/.vimrc"
  fi

#  if [ "$DEFAULT_USER" == 'root' ]; then
#    chown -R "$DEV_USER:$DEV_USER" "/home/$DEV_USER"
#    chown -R "$DEV_USER:$DEV_USER" "$inst_dir"
#  fi

  exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER"
  mark_as_installed vimbundles
}


restore_vim_bundles()
{
  echo ""
  hdr "Restoring vim & pathogen bundles..."
  echo ""

  local inst_dir="/home/$DEV_USER/.vim/bundle"

  if [ -d "/home/$DEV_USER/.bootstrap/backup/orig/dotvim/bundle" ]; then
    inf "Restoring vim bundles..."
    exec_cmd "rm -rf $inst_dir"
    exec_cmd "cp -R /home/$DEV_USER/.bootstrap/backup/orig/dotvim/bundle $inst_dir"
    exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER/.vim"
  else
    inf "Removing vim bundles..."
    exec_cmd "rm -rf $inst_dir"
  fi

  # handle .vimrc
  if [ -f "/home/$DEV_USER/.bootstrap/backup/orig/dotvimrc" ]; then
    exec_cmd "cp /home/$DEV_USER/.bootstrap/backup/orig/dotvimrc /home/$DEV_USER/.vimrc"
  fi

  exec_cmd "chown -R $DEV_USER:$DEV_USER /home/$DEV_USER"
  mark_as_uninstalled vimbundles
}


enable_vim_ycm()
{
  echo ""
  hdr "Installing the YouCompleteMe vim plugin..."
  echo ""

  local inst_dir="/home/$DEV_USER/.vim/bundle"

  ## YouCompleteMe
  git clone https://github.com/valloric/youcompleteme
  cd "$inst_dir/youcompleteme"
  git submodule update --init --recursive
  local ycm_opts=

  if command_exists go; then
    ycm_opts="${ycm_opts} --gocode-completer"
  fi

  if command_exists node; then
    ycm_opts="${ycm_opts} --tern-completer"
  fi

  #ycm_opts="--all"

  if [ "$DEFAULT_USER" == 'root' ]; then
    su -c "$inst_dir/youcompleteme/install.py $ycm_opts" "$DEV_USER"
  else
    exec_nonprv_cmd "$inst_dir/youcompleteme/install.py $ycm_opts"
  fi
}

