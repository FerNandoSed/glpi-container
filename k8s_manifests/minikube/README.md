# Deployment using minikube

## Requisites

It is mandatory for this script to work having [minikube](https://minikube.sigs.k8s.io/docs/start/) and virtualbox already installed.

## Deployment

Go to minikube directory and execute `deploy_glpi.sh`

```bash
cd k8s_manifests/minikube
./deploy_glpi.sh

😄  minikube v1.16.0 on Ubuntu 20.04
✨  Using the virtualbox driver based on existing profile
👍  Starting control plane node minikube in cluster minikube
🏃  Updating the running virtualbox "minikube" VM ...
🐳  Preparing Kubernetes v1.20.0 on Docker 20.10.0 ...
🔎  Verifying Kubernetes components...
🔎  Verifying ingress addon...
🌟  Enabled addons: storage-provisioner, default-storageclass, ingress
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
🔎  Verifying ingress addon...
🌟  The 'ingress' addon is enabled
namespace/glpi created
secret/glpi-secrets created
deployment.apps/glpi created
persistentvolumeclaim/glpi-data-pvc created
service/web created
ingress.networking.k8s.io/glpi-ingress created
persistentvolumeclaim/mariadb-pvc created
deployment.apps/db created
service/db created
configmap/php-fpm-config-configmap created
configmap/nginx-config-configmap created
Checking hosts file for IP 192.168.99.110 and domain glpi.cobayops.local...
Please change IP for glpi.cobayops.local in hosts file

```

The last message will tell us if it is necessary to modify or append the line "$(minikube ip) <Domain>" to our local hosts file. This is so we can access the service using the hostname **glpi.cobayops.local**, specified in the ingress controller configuration.
