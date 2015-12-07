FROM jubicoy/nginx-php:latest
ENV DRUPAL_VERSION 7.41

RUN apt-get update && apt-get dist-upgrade -y && \
    apt-get -y install php5-fpm php5-mysql php-apc \
    php5-imagick php5-imap php5-mcrypt php5-curl \
    php5-cli php5-gd php5-pgsql php5-sqlite \
    php5-common php-pear curl php5-json php5-redis php5-memcache \
    gzip netcat drush mysql-client

RUN curl -k http://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz | tar zx -C /var/www/
RUN mv /var/www/drupal-${DRUPAL_VERSION} /var/www/drupal
RUN cp -rf /var/www/drupal/sites /tmp/

# Add configuration files
ADD config/default.conf /etc/nginx/conf.d/default.conf
ADD config/settings.php /workdir/settings.php
ADD entrypoint.sh /workdir/entrypoint.sh

RUN chown -R 104:0 /var/www && chmod -R g+rw /var/www && \
    chmod a+x /workdir/entrypoint.sh && chmod g+rw /workdir

VOLUME ["/var/www/drupal/sites"]

USER 104
