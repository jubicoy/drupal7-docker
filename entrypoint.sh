#!/bin/bash
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /workdir/passwd.template > /tmp/passwd
export LD_PRELOAD=libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/etc/group

if [ ! -f /var/www/drupal/robots.txt ]; then
  mv -f /workdir/robots.txt /var/www/drupal/sites/robots.txt
fi

if [ ! -d /var/www/drupal/sites/default ]; then
  # Copy initial sites and configuration
  cp -arf /tmp/sites/* /var/www/drupal/sites/
  echo "Will now download modules"
  # Download modules
  IFS=';' read -r -a modules <<< "$DRUPAL_MODULES"
  for module in "${modules[@]}"
  do
    echo "Downloading module $module"
    drush dl ${module}-7.x -y --destination=/var/www/drupal/sites/all/modules/
  done

  # Download themes
  IFS=';' read -r -a themes <<< "$DRUPAL_THEMES"
  for theme in "${themes[@]}"
  do
    echo "Downloading theme $theme"
    drush dl $theme -y --destination=/var/www/drupal/sites/all/themes/
  done
else
  echo "Applying required database updates"
  (cd /var/www/drupal/; drush updb)
fi

# Move Nginx configuration if does not exist
if [ ! -f /var/www/drupal/sites/conf/default.conf ]; then
    # Move Nginx configuration to volume
    mkdir -p /var/www/drupal/sites/conf/
    mv /workdir/default.conf /var/www/drupal/sites/conf/default.conf
fi

if [ ! -f /tmp/dav_auth ] && [ ! -z "$DAV_PASS" ] && [ ! -z "$DAV_USER" ]; then
  # Create WebDAV Basic auth user
  echo ${DAV_PASS}|htpasswd -i -c /tmp/dav_auth ${DAV_USER}
fi

if [ ! -f /var/www/drupal/sites/conf/php.ini ]; then
	mv /tmp/php.ini /var/www/drupal/sites/conf/php.ini
fi

exec "$@"
