#!/bin/bash
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /workdir/passwd.template > /tmp/passwd
export LD_PRELOAD=libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/etc/group

# Copy configuration files
if [ ! -f /var/www/drupal/sites/default/settings.php ]; then
    cp -arf /tmp/sites/* /var/www/drupal/sites/
    cp -af /workdir/settings.php /var/www/drupal/sites/default/settings.php

    sed -i "s/DATABASE_NAME/${MYSQL_DATABASE}/g" /var/www/drupal/sites/default/settings.php
    sed -i "s/USERNAME/${MYSQL_USER}/g" /var/www/drupal/sites/default/settings.php
    sed -i "s/PASSWORD/${MYSQL_PASSWORD}/g" /var/www/drupal/sites/default/settings.php
fi

exec "/usr/bin/supervisord"
