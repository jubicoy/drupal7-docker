#!/bin/bash
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /workdir/passwd.template > /tmp/passwd
export LD_PRELOAD=libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/etc/group

#sed -i "s/DAV_HOSTNAME/${DAV_HOSTNAME}/g" /etc/nginx/conf.d/webdav.conf

if [ ! -d /var/www/drupal/sites/default ]; then
  # Copy initial sites and configuration
  cp -arf /tmp/sites/* /var/www/drupal/sites/
fi

if [ ! -f /tmp/dav_auth ]; then
  # Create WebDAV Basic auth user
  echo ${DAV_PASS}|htpasswd -i -c /tmp/dav_auth ${DAV_USER}
fi

exec "/usr/bin/supervisord"
