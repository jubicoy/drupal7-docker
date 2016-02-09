FROM jubicoy/nginx-php:latest
ENV DRUPAL_VERSION 7.42

RUN apt-get update && apt-get dist-upgrade -y && \
    apt-get -y install php5-fpm php5-mysql php-apc \
    php5-imagick php5-imap php5-mcrypt php5-curl \
    php5-cli php5-gd php5-pgsql php5-sqlite \
    php5-common php-pear curl php5-json php5-redis php5-memcache \
    gzip netcat drush mysql-client

# Sabre WebDAV support
# RUN apt-get install -y php-sabre-dav

RUN curl -k https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz | tar zx -C /var/www/
RUN mv /var/www/drupal-${DRUPAL_VERSION} /var/www/drupal
RUN cp -rf /var/www/drupal/sites /tmp/

# Composer for Sabre installation
ENV COMPOSER_VERSION 1.0.0-alpha11
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION}

# WebDAV configuration
RUN apt-get install -y apache2-utils
RUN mkdir -p /var/www/webdav && mkdir -p /var/www/webdav/locks && chmod -R 777 /var/www/webdav/locks
ADD config/webdav.conf /etc/nginx/conf.d/webdav.conf
ADD sabre/index.php /var/www/webdav/index.php

# Sabre with composer
RUN cd /var/www/webdav && composer require sabre/dav ~3.1.0 && composer update sabre/dav && cd

# Add configuration files
#ADD config/default.conf /etc/nginx/conf.d/default.conf
ADD config/default.conf /workdir/default.conf
RUN rm -rf /etc/nginx/conf.d/default.conf && ln -s /var/www/drupal/sites/conf/default.conf /etc/nginx/conf.d/default.conf
ADD config/settings.php /workdir/settings.php
ADD entrypoint.sh /workdir/entrypoint.sh

RUN chown -R 104:0 /var/www && chmod -R g+rw /var/www && \
    chmod a+x /workdir/entrypoint.sh && chmod g+rw /workdir

VOLUME ["/var/www/drupal/sites"]

# Additional CA certificate bundle (Mozilla)
RUN mkdir -p /usr/local/share/ca-certificates/mozilla.org
ADD config/mozilla.crt /usr/local/share/ca-certificates/mozilla.org/ca-bundle.crt
RUN update-ca-certificates

EXPOSE 5000
EXPOSE 5005

USER 104
