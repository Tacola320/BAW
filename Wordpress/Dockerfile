FROM wordpress:php7.4-apache

RUN apt-get update \
    && apt-get install -y supervisor mariadb-server --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

COPY files/config/custom.ini $PHP_INI_DIR/conf.d/

COPY --chown=www-data:www-data files/html /var/www/html

COPY files/sql/ /tmp/

COPY files/mysql-entrypoint.sh /usr/bin/

RUN chmod +x /usr/bin/mysql-entrypoint.sh 

ENV WORDPRESS_SITE_URL localhost

COPY supervisord.conf /etc/supervisord.conf

EXPOSE 80

RUN chown -R www-data:www-data /var/www

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]