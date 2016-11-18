FROM jubicoy/nginx-php:maintenance
ENV DRUPAL_VERSION 7.52

RUN apt-get update && \
    apt-get -y install php7.0-fpm php7.0-mysql php-apcu \
    php-imagick php7.0-imap php7.0-mcrypt php7.0-curl \
    php7.0-cli php7.0-gd php7.0-pgsql php7.0-sqlite php7.0-zip \
    php7.0-common php-pear curl php7.0-json php-redis php-memcache \
    gzip netcat drush mysql-client imagemagick make php7.0-dev php-pear vim && \
    apt-get clean



RUN curl -k https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz | tar zx -C /var/www/
RUN mv /var/www/drupal-${DRUPAL_VERSION} /var/www/drupal
RUN cp -rf /var/www/drupal/sites /tmp/
ADD config/default.settings.php /tmp/sites/default/

# Composer for Sabre installation
ENV COMPOSER_VERSION 1.0.0-alpha11
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION}

# WebDAV configuration
RUN apt-get install -y apache2-utils && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/www/webdav && mkdir -p /var/www/webdav/locks && chmod -R 777 /var/www/webdav/locks
ADD config/webdav.conf /etc/nginx/conf.d/webdav.conf
ADD sabre/index.php /var/www/webdav/index.php

# Sabre with composer
RUN cd /var/www/webdav && composer require sabre/dav ~3.1.0 && composer update sabre/dav && cd

# Add configuration files
RUN mkdir -p /var/www/drupal/sites/default
COPY config/default.settings.php /workdir/settings.php
RUN cp /workdir/settings.php /var/www/drupal/sites/default/settings.php

ADD config/default.conf /workdir/default.conf
RUN rm -rf /etc/nginx/conf.d/default.conf && ln -s /var/www/drupal/sites/conf/default.conf /etc/nginx/conf.d/default.conf
ADD entrypoint.sh /workdir/entrypoint.sh
ADD config/nginx.conf /etc/nginx/nginx.conf

# Install custom PHP extensions
# This is disabled for now since PHP7 support for jsmin is still poor
#RUN pecl install jsmin
#RUN echo 'extension="jsmin.so"' >> /etc/php/7.0/fpm/php.ini

RUN chown -R 104:0 /var/www && chmod -R g+rw /var/www && \
    chmod a+x /workdir/entrypoint.sh && chmod g+rw /workdir

VOLUME ["/var/www/drupal/sites"]

# Additional CA certificate bundle (Mozilla)
ADD mailchimp-ca.sh /workdir/mailchimp-ca.sh
RUN chmod a+x /workdir/mailchimp-ca.sh && bash /workdir/mailchimp-ca.sh
RUN update-ca-certificates

# PHP max upload size
RUN sed -i '/upload_max_filesize/c\upload_max_filesize = 250M' /etc/php/7.0/fpm/php.ini
RUN sed -i '/post_max_size/c\post_max_size = 250M' /etc/php/7.0/fpm/php.ini
# PHP max execution time
RUN sed -i '/max_execution_time/c\max_execution_time = 60' /etc/php/7.0/fpm/php.ini

EXPOSE 5000
EXPOSE 5005

USER 104

CMD ["/usr/bin/supervisord"]
