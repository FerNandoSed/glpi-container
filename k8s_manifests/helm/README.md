# GLPI Installation with Helm

## Requisites

It is assumed that you have created a cluster with nginx-ingress-controller and cert-manager installed.

## Installation process

In this example, 2 GLPI instances will be installed, each contained in its namespace. Let's call these instances **glpi-a** and **glpi-b**.

### Create namespaces

```bash
kubectl create namespace glpi-a
kubectl create namespace glpi-b
```

### Deploy databases

```bash
MYSQL_DATABASE=glpi_db
MYSQL_PASSWORD=$(cat /dev/urandom | tr -dc a-zA-Z0-9\[\]\.\!\&\_\-\| | head -c24)
MYSQL_USER=glpidbuser
kubectl create secret generic glpi-secrets --from-literal=MYSQL_RANDOM_ROOT_PASSWORD=yes --from-literal=MYSQL_USER=$MYSQL_USER --from-literal=MYSQL_DATABASE=$MYSQL_DATABASE --from-literal=MYSQL_PASSWORD=$MYSQL_PASSWORD -n glpi-a
MYSQL_PASSWORD=$(cat /dev/urandom | tr -dc a-zA-Z0-9\[\]\.\!\&\_\-\| | head -c24)
kubectl create secret generic glpi-secrets --from-literal=MYSQL_RANDOM_ROOT_PASSWORD=yes --from-literal=MYSQL_USER=$MYSQL_USER --from-literal=MYSQL_DATABASE=$MYSQL_DATABASE --from-literal=MYSQL_PASSWORD=$MYSQL_PASSWORD -n glpi-b
kubectl apply -f db.yml -n glpi-a
kubectl apply -f db.yml -n glpi-b
```

### Create NFS servers for PersistentVolume

```bash
kubectl apply -f nfs-a.yml -n glpi-a
kubectl apply -f nfs-b.yml -n glpi-b
```

### Create Persistent Volumes

This will create Persistent Volumens with RWX access mode, so we can scale the deployment through out several nodes.

```bash
kubectl apply -f pv-glpi-a.yml -n glpi-a
kubectl apply -f pv-glpi-b.yml -n glpi-b
```

### Install Helm

```bash
helm install -n glpi-a --atomic --values glpi-a.yml glpi ./glpi
helm install -n glpi-b --atomic --values glpi-b.yml glpi ./glpi
```
