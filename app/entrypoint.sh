#!/bin/bash

set -u

FILE_DIRS="
_cache
_dumps
_locales
_log
_plugins
_sessions
_uploads
_cron
_graphs
_lock
_pictures
_rss
_tmp
"

LOCAL_DEFINE_CONTENT="<?php
define('GLPI_VAR_DIR', '$GLPI_VAR_DIR');
define('GLPI_LOG_DIR', '$GLPI_LOG_DIR');
"

## From wait-for-it.sh ##
# Credits https://github.com/vishnubob/wait-for-it/blob/master/wait-for-it.sh
while :
do
    echo -n > /dev/tcp/$MYSQL_HOST/3306
    DBISREADY=$?

    ## if DB is down
    if [[ $DBISREADY -eq 1 ]]; then
        sleep 1
        echo $MYSQL_HOST not ready yet...
    ## if it's up
    else
        echo $MYSQL_HOST ready!!!
        break
    fi
done
# / From wait-for-it.sh #

set -e

if [ -f $GLPI_CONFIG_DIR/config_db.php ]; then
    [ -f $GLPI_DOCUMENT_ROOT/install/install.php ] && rm -v $GLPI_DOCUMENT_ROOT/install/install.php
    php-fpm
else
    for DIR in $FILE_DIRS ; do
        mkdir $GLPI_VAR_DIR/$DIR -p
    done

    chown -Rv www-data:www-data $GLPI_CONFIG_DIR $GLPI_LOG_DIR $GLPI_VAR_DIR

    cd $GLPI_DOCUMENT_ROOT    

    echo $MYSQL_PASSWORD

    php bin/console db:install --db-host=$MYSQL_HOST \
        --db-name=$MYSQL_DATABASE \
        --db-user=$MYSQL_USER \
        --db-password="$MYSQL_PASSWORD" \
        -n \
        --force
    
    echo $LOCAL_DEFINE_CONTENT > $GLPI_CONFIG_DIR/local_define.php

    chown -Rv www-data:www-data $GLPI_CONFIG_DIR $GLPI_LOG_DIR $GLPI_VAR_DIR

    rm -v $GLPI_DOCUMENT_ROOT/install/install.php

    php-fpm
fi