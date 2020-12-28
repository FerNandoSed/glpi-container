FROM nginx:stable-alpine

# GLPI Instalation
RUN apk add wget tar \
    && mkdir /var/www && cd /var/www/ \
    && wget https://github.com/glpi-project/glpi/releases/download/9.5.3/glpi-9.5.3.tgz \
    && tar xf glpi-9.5.3.tgz \
    && rm /var/www/glpi-9.5.3.tgz