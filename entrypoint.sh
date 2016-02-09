#!/bin/bash
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /workdir/passwd.template > /tmp/passwd
export LD_PRELOAD=libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/etc/group

IFS=';' read -r -a modules <<< "$DRUPAL_MODULES"

if [ ! -d /var/www/drupal/sites/default ]; then
  # Copy initial sites and configuration
  cp -arf /tmp/sites/* /var/www/drupal/sites/

  # Download modules
  for module in "${modules[@]}"
  do
    echo "Downloading module $module"
    drush dl $module -y --destination=/var/www/drupal/sites/all/modules/
  done

fi

# Move Nginx configuration if does not exist
if [ ! -f /var/www/drupal/sites/conf/default.conf ]; then
  # Move Nginx configuration to volume
  mkdir -p /var/www/drupal/sites/conf/
  mv /workdir/default.conf /var/www/drupal/sites/conf/default.conf
fi

if [ ! -f /tmp/dav_auth ]; then
  # Create WebDAV Basic auth user
  echo ${DAV_PASS}|htpasswd -i -c /tmp/dav_auth ${DAV_USER}
fi

exec "/usr/bin/supervisord"
