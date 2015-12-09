#!/bin/bash
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /workdir/passwd.template > /tmp/passwd
export LD_PRELOAD=libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/etc/group

# Copy configuration files
if [ ! -d /var/www/drupal/sites/default ]; then
    cp -arf /tmp/sites/* /var/www/drupal/sites/

    #echo "Drupal database host: ${DRUPAL_SERVICE_NAME}-db"
    #echo "MySQL username:password: ${MYSQL_USER}:${MYSQL_PASSWORD}"
    #echo "Drupal site name: ${DRUPAL_SITE_NAME}"

    #sleep 30s

    # Wait until MySQL instance is running
    #while ! nc -z ${DRUPAL_SERVICE_NAME}-db 3306; do
    #  sleep 1s
    #done

    #cd /var/www/drupal
    #drush site-install -y standard \
    #  --db-url=mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${DRUPAL_SERVICE_NAME}-db/drupal \
    #  --site-name="${DRUPAL_SITE_NAME}" --account-name=admin --account-pass=${MYSQL_PASSWORD}

    #cp -af /workdir/settings.php /var/www/drupal/sites/default/default.settings.php

    #sed -i "s/DATABASE_NAME/${MYSQL_DATABASE}/g" /var/www/drupal/sites/default/default.settings.php
    #sed -i "s/USERNAME/${MYSQL_USER}/g" /var/www/drupal/sites/default/default.settings.php
    #sed -i "s/PASSWORD/${MYSQL_PASSWORD}/g" /var/www/drupal/sites/default/default.settings.php
fi

exec "/usr/bin/supervisord"
