FROM php:7.4-fpm-alpine

# PHP modules dependencies
RUN apk add --no-cache \
        libjpeg-turbo-dev \
        libpng-dev \
        libldap \
        krb5-dev \
        libxml2 \
        freetype-dev \
        libxml2-dev \
        libzip-dev \
        imap-dev \
        c-client \
        openssl-dev \
        openldap-dev \
        icu-dev \
        bzip2-dev \
        libbz2 \
        libzip \
        libintl \
        libgd \
        icu-libs && \
    mkdir -p /usr/src/php/ext/apcu && \
    curl -fsSL https://github.com/krakjoe/apcu/archive/v5.1.18.tar.gz | tar xvz -C /usr/src/php/ext/apcu --strip 1 && \
    docker-php-ext-install -j$(nproc) apcu

# Install PHP dependencies
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-configure imap --with-imap-ssl --with-kerberos && \
    docker-php-ext-install -j$(nproc) mysqli ldap xmlrpc exif imap gd intl bz2 opcache zip && \
    docker-php-source delete

# GLPI Instalation
RUN apk add wget tar && \
    mkdir -p /usr/local/src && cd /usr/local/src && \
    wget -O- https://github.com/glpi-project/glpi/releases/download/9.5.6/glpi-9.5.6.tgz | tar xzf -

# Cleaning
RUN apk del \
        libjpeg-turbo-dev \
        libpng-dev \
        krb5-dev libxml2 \
        freetype-dev \
        libxml2-dev \
        libzip-dev \
        wget \
        imap-dev \
        openssl-dev \
        openldap-dev \
        icu-dev \
        bzip2-dev

# Copy entrypoint script
RUN apk add bash
COPY ./entrypoint.sh /root/entrypoint.sh
RUN  chmod 750 /root/entrypoint.sh
