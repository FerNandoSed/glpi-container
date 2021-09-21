#!/bin/bash

# TODO:
#   - find a way to upgrade by changing glpi image

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

# Define directories, if not already defined by environment variables.
function init_vars {

    if [ -z ${GLPI_CONFIG_DIR:-""} ]; then
        GLPI_CONFIG_DIR=$GLPI_DATA/confs
    fi

    if [ -z ${GLPI_DOCUMENT_ROOT:-""} ]; then
        GLPI_DOCUMENT_ROOT=$GLPI_DATA/www
    fi

    if [ -z ${GLPI_LOG_DIR:-""} ]; then
        GLPI_LOG_DIR=$GLPI_DATA/logs
    fi

    if [ -z ${GLPI_VAR_DIR:-""} ]; then
        GLPI_VAR_DIR=$GLPI_DATA/files
    fi

LOCAL_DEFINE_CONTENT="<?php
define('GLPI_VAR_DIR', '$GLPI_VAR_DIR');
define('GLPI_LOG_DIR', '$GLPI_LOG_DIR');
"
    DOWNSTREAM_CONTENT="<?php
define('GLPI_CONFIG_DIR', '$GLPI_CONFIG_DIR');

if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
   require_once GLPI_CONFIG_DIR . '/local_define.php';
}"

}

function check_dirs {
    echo Checking directories...
    for dir in \
        $GLPI_DOCUMENT_ROOT \
        $GLPI_CONFIG_DIR \
        $GLPI_LOG_DIR \
        $GLPI_VAR_DIR \
        ;
        do
        if [ -d $dir ]; then
            echo Directory $dir exists...
        else
            echo Directory $dir does not exist. Creating...
            mkdir -p $dir
        fi
    done
}

function copy_glpi {
    # This function transfers GLPI to document root. Document root should be a persistent module.

    # check if GLPI is already copied
    if [ -f $GLPI_DOCUMENT_ROOT/index.php ]; then
        echo "Not copying GLPI, since is already in document root"
    else
        echo "Copying GLPI (index.php is missing)"
        if [ $(echo $GLPI_DOCUMENT_ROOT | rev | cut -d'/' -f1 | rev) = "glpi" ]; then
            tar -C $GLPI_DOCUMENT_ROOT/.. -xf /usr/local/src/glpi-9.5.6.tgz
        else
            tar -C $GLPI_DOCUMENT_ROOT -xf /usr/local/src/glpi-9.5.6.tgz
            mv $GLPI_DOCUMENT_ROOT/glpi/* $GLPI_DOCUMENT_ROOT/
            rm -r $GLPI_DOCUMENT_ROOT/glpi
        fi
        echo "chowning $GLPI_DOCUMENT_ROOT to www-data..."
        chown -R www-data:www-data $GLPI_DOCUMENT_ROOT
    fi
}

function run_glpi {
    echo "GLPI is installed..."
    echo "starting php-fpm..."
    php-fpm
}

# Check vars before installation
init_vars

# If GLPI is installed, run php-fpm
if [ -f $GLPI_CONFIG_DIR/config_db.php ]; then
    run_glpi

# Install GLPI in other case
else

    check_dirs
    copy_glpi

    # Create directories for GLPI files, since this is a custom position for GLPI variable data
    if [ $GLPI_VAR_DIR != $GLPI_DOCUMENT_ROOT ]; then
        for DIR in $FILE_DIRS ; do
            mkdir $GLPI_VAR_DIR/$DIR -p
        done
    fi

    cd $GLPI_DOCUMENT_ROOT

    # This installs GLPI
    php bin/console db:install --db-host=$MYSQL_HOST \
        --db-name=$MYSQL_DATABASE \
        --db-user=$MYSQL_USER \
        --db-password="$MYSQL_PASSWORD" \
        -n \
        --force
    
    # It is necessary to specify customs directories locations.
    echo $LOCAL_DEFINE_CONTENT > $GLPI_CONFIG_DIR/local_define.php
    echo $DOWNSTREAM_CONTENT > $GLPI_DOCUMENT_ROOT/inc/downstream.php

    # GLPI should be run with www-data
    echo "chowning custom directories to www-data..."
    chown -R www-data:www-data $GLPI_CONFIG_DIR $GLPI_LOG_DIR $GLPI_VAR_DIR

    # This is useful for security purposes and for determining if GLPI is already installed
    rm -v $GLPI_DOCUMENT_ROOT/install/install.php

    run_glpi
fi
