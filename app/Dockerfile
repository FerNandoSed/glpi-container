FROM php:7.4-apache

## PHP Modules
RUN apt-get update && apt-get install -y \
        libfreetype6 \
        libjpeg62-turbo \
        libpng16-16 \
        libldap-2.4-2 \
        libc-client2007e libkrb5-3 libxml2 \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libldap-dev \
        libc-client2007e-dev libkrb5-dev libxml2-dev libbz2-dev libzip-dev\
    && mkdir -p /usr/src/php/ext/apcu \
    && curl -fsSL https://github.com/krakjoe/apcu/archive/v5.1.18.tar.gz | tar xvz -C /usr/src/php/ext/apcu --strip 1 \
    && docker-php-ext-install -j$(nproc) apcu
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-imap-ssl --with-kerberos \
    && docker-php-ext-install -j$(nproc) mysqli ldap xmlrpc exif imap gd intl bz2 opcache zip \
    && docker-php-source delete

# GLPI Instalation
RUN apt-get update && apt-get install wget -y \
    && cd /var/www/ \
    && wget https://github.com/glpi-project/glpi/releases/download/9.5.3/glpi-9.5.3.tgz \
    && tar xf glpi-9.5.3.tgz \
    && rm /var/www/glpi-9.5.3.tgz \
    && chown -R www-data:www-data /var/www/glpi
RUN rm /etc/apache2/sites-enabled/000-default.conf
COPY ./glpi.conf /etc/apache2/sites-enabled/glpi.conf

# Cleaning
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt remove wget libfreetype6-dev libjpeg62-turbo-dev libpng-dev libldap-dev libc-client2007e-dev libkrb5-dev gcc autoconf gcc-8 -y && apt autoremove -y

# Copy entrypoint script
COPY ./entrypoint.sh /root/entrypoint.sh
RUN  chmod 750 /root/entrypoint.sh