### google cloud platform cli
# https://cloud.google.com/sdk/downloads#versioned
###

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab


install_gcloud()
{
  echo ""
  hdr "Installing google cloud sdk (aka gcloud)..."
  echo ""

  local install=0
  local CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"

  if command_exists gcloud; then
    if [ $(gcloud version | awk '{ print $4; exit }') == "$GCLOUD_VER" ]; then
      warn "gcloud is already installed."
      install=1
    else
      inf "gcloud is already installed...but versions don't match"
      exec_cmd "rm -rf /home/$DEV_USER/bin/google-cloud-sdk"
      mark_as_uninstalled gcloud
    fi
  fi

  if [ $install -eq 0 ]; then
	echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
	curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  #  exec_nonprv_cmd "wget -O /tmp/gcloud.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VER}-linux-x86_64.tar.gz"
#
#    local checksum=$(sha256sum /tmp/gcloud.tar.gz | awk '{ print $1 }')
#    if [ "$checksum" != "$GCLOUD_CHECKSUM" ]; then
#      error "checksum verification failed:"
#      error "  expected: $GCLOUD_CHECKSUM"
#      error "    actual: $checksum"
#      exit 1
#    fi
#
#    exec_nonprv_cmd "tar -zxvf /tmp/gcloud.tar.gz -C /home/$DEV_USER/bin/"
#    exec_nonprv_cmd "/home/$DEV_USER/bin/google-cloud-sdk/install.sh --quiet --rc-path /home/$DEV_USER/.profile --usage-reporting true --command-completion true --path-update true"
#    exec_nonprv_cmd "rm /tmp/gcloud.tar.gz"
    
    if ! { sudo apt-get update 2>&1 ; } | grep -q 'Err:3 spacewalk.pg-dev.net'; then
	   sudo apt-get install google-cloud-sdk 
    else
	    err "apt-get update failed"
    fi

#    inf "updating ~/.bootstrap/profile.d/ with gcloud..."
#    echo "# The following PATH was automatically added by $PROGDIR/$PROGNAME" > "/home/$DEV_USER/.bootstrap/profile.d/gcloud.sh"
#    echo "export GCLOUDPATH=/home/$DEV_USER/bin/google-cloud-sdk" >> "/home/$DEV_USER/.bootstrap/profile.d/gcloud.sh"
#    echo 'export PATH=$PATH:$GCLOUDPATH/bin' >> "/home/$DEV_USER/.bootstrap/profile.d/gcloud.sh"


    # we don't want to overlay dot files after we modify .profile with gcloud
    mark_dotprofile_as_touched gcloud
    mark_as_installed gcloud

    # User must log off for these changes to take effect
    LOGOFF_REQ=1
  fi
}


uninstall_gcloud_orig()
{
  echo ""
  hdr "Uninstalling google cloud sdk (aka gcloud)..."
  echo ""

  if command_exists gcloud; then
    exec_cmd "rm -rf /home/$DEV_USER/bin/google-cloud-sdk"
    mark_as_uninstalled gcloud

    # clean up the ~/.profile
    exec_cmd "sed -i.gcloudpath-bak '/google-cloud-sdk/d' /home/$DEV_USER/.profile"
    exec_cmd "sed -i.gcloudcomment-bak '/Google Cloud SDK/d' /home/$DEV_USER/.profile"
    exec_cmd "sed -i.gcloudcomment2-bak '/gcloud/d' /home/$DEV_USER/.profile"

    if [ -f "/home/$DEV_USER/.bootstrap/touched-dotprofile/gcloud" ]; then
      exec_cmd "rm /home/$DEV_USER/.bootstrap/touched-dotprofile/gcloud"
    fi
  else
    warn "gcloud is not installed"
  fi
}

uninstall_gcloud()
{
  echo ""
  hdr "Uninstalling google cloud sdk (aka gcloud)..."
  echo ""

  if command_exists gcloud; then
    exec_cmd 'apt-get purge -y google-cloud-sdk >/dev/null'
    mark_as_uninstalled gcloud
  else
    warn "gcloud is not installed"
  fi

  if [ -f "/etc/apt/sources.list.d/google-cloud-sdk.list" ]; then
    exec_cmd 'rm /etc/apt/sources.list.d/google-cloud-sdk.list'
  fi

}



