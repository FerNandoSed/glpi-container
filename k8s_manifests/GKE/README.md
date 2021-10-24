# Running GLPI Over GKE

## Create the cluster in GCP
A kubernetes cluster can be created at the command line with the following sentence. It is assumed that you have already loged in with `gcloud`.

```bash
gcloud container clusters create cluster-1 --zone=southamerica-east1-c
WARNING: Starting in January 2021, clusters will use the Regular release channel by default when `--cluster-version`, `--release-channel`, `--no-enable-autoupgrade`, and `--no-enable-autorepair` flags are not specified.
WARNING: Currently VPC-native is the default mode during cluster creation for versions greater than 1.21.0-gke.1500. To create advanced routes based clusters, please pass the `--no-enable-ip-alias` flag
WARNING: Starting with version 1.18, clusters will have shielded GKE nodes by default.
WARNING: Your Pod address range (`--cluster-ipv4-cidr`) can accommodate at most 1008 node(s). 
WARNING: Starting with version 1.19, newly created clusters and node-pools will have COS_CONTAINERD as the default node image when no image type is specified.
Creating cluster cluster-1 in southamerica-east1-c...⠏   
```
## Install NGINx Ingress Controller with Helm

Default ingress in GKE is not as flexible as nginx ingress controller, so we should use nginx instead of GKE ingress controller.

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx
```
If the nginx-ingress-controller is correctly installed, then we should see the following output:
```
NAME: ingress-nginx
LAST DEPLOYED: Sun Oct 17 18:53:15 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace default get services -o wide -w ingress-nginx-controller'

An example Ingress that makes use of the controller:
...
```

## Install Cert Manager
This will help us by issuing free certificates for HTTPS, signed by Let's Encrypt CA. Execute the following sentence for the installation ([source](https://cert-manager.io/docs/installation/helm/)).
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.crds.yaml
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.5.4
```
Expected output:
```
NAME: cert-manager
LAST DEPLOYED: Sun Oct 17 19:12:36 2021
NAMESPACE: cert-manager
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
cert-manager v1.5.4 has been deployed successfully!
...
```
Finally, create the ClusterIssuer object.
```
kubectl apply -f cluster-issuer.yml
```
## Create NFS-Share for GLPI

We should be able to horizontally scale this appication and for that we will need a storage with _READWRITEMANY_ _accessMode_ type. Default storage class will not succeed, so we need another solution. An NFS share can comply with our requirement.

Create disk:
```bash
gcloud compute disks create --size=100GB --zone=southamerica-east1-c nfs-disk
```

Create NFS deployment:

```bash
kubectl apply -f nfs.yml
```

## Deploy GLPI

First let's create the namespace **glpi** ad the the secrets for database:

```bash
MYSQL_DATABASE=glpi_db
MYSQL_PASSWORD=$(cat /dev/urandom | tr -dc a-zA-Z0-9\[\]\.\!\&\_\-\| | head -c24)
MYSQL_USER=glpidbuser
kubectl create secret generic glpi-secrets --from-literal=MYSQL_RANDOM_ROOT_PASSWORD=yes --from-literal=MYSQL_USER=$MYSQL_USER --from-literal=MYSQL_DATABASE=$MYSQL_DATABASE --from-literal=MYSQL_PASSWORD=$MYSQL_PASSWORD -n glpi
```

Then, let's deploy glpi:

```bash
kubectl apply -f glpi.yml -f db.yml -f php-configmap.yml -f nginx-configmap.yml -n glpi
deployment.apps/glpi created
persistentvolumeclaim/glpi-data-pvc created
persistentvolume/glpi-data created
service/web created
ingress.networking.k8s.io/glpi-ingress created
persistentvolumeclaim/mariadb-pvc created
deployment.apps/db created
service/db created
configmap/php-fpm-config-configmap created
configmap/nginx-config-configmap created
```
