#!/bin/bash

set -eu

ENVFILE=../../env
NAMESPACE=glpi

# Initiate minikube and enable ingress addon
if [ -n "$(minikube status | grep 'host: Running')" ]; then
    echo minikube already running
else
    minikube start --driver=virtualbox && minikube addons enable ingress
    echo Waiting for nginx ingress to be completly configured.
    sleep 20
fi

## Create namespace
if [ "$(kubectl get namespace | cut -f1 -d' ' | grep $NAMESPACE)" = "$NAMESPACE" ]; then
    echo Namespace $NAMESPACE exists
else
    kubectl create namespace $NAMESPACE
fi

## Create secrets
if [ -f "$ENVFILE" ]; then
    source $ENVFILE
else
    MYSQL_DATABASE=glpi_db
    MYSQL_PASSWORD=$(cat /dev/urandom | tr -dc a-zA-Z0-9\[\]\.\!\&\_\-\| | head -c24)
    MYSQL_USER=glpidbuser
fi
if [ "$(kubectl get secrets -n $NAMESPACE | cut -f1 -d' ' | grep glpi-secrets)" = "glpi-secrets" ]; then
    echo Secret glpi-secrets exists
else
    kubectl create secret generic glpi-secrets --from-literal=MYSQL_RANDOM_ROOT_PASSWORD=yes --from-literal=MYSQL_USER=$MYSQL_USER --from-literal=MYSQL_DATABASE=$MYSQL_DATABASE --from-literal=MYSQL_PASSWORD=$MYSQL_PASSWORD -n $NAMESPACE
fi

## Deploy app

kubectl apply -f glpi.yml -f db.yml -f php-configmap.yml -f nginx-configmap.yml -n $NAMESPACE

# Check hosts file
# echo "Please add \"$(minikube ip) $DOMAIN\" to your local hosts file"
MINIKUBEIP=$(minikube ip)
DOMAIN=glpi.cobayops.local
echo Checking hosts file for IP $MINIKUBEIP and domain $DOMAIN...
if [ -n "$( grep ^$MINIKUBEIP /etc/hosts )" ]; then
    if [ "$(grep ^$MINIKUBEIP /etc/hosts | grep $DOMAIN /etc/hosts )" ] ; then
        echo $MINIKUBEIP for $DOMAIN is correctly configured in hosts file
    else
        echo Please append $DOMAIN to $MINIKUBEIP in hosts file
    fi
else
    if [ -n "$( grep $DOMAIN /etc/hosts )" ] ; then
        echo Please change IP for $DOMAIN in hosts file
    else
        echo Please append $MINIKUBEIP $DOMAIN to hosts file
    fi
fi