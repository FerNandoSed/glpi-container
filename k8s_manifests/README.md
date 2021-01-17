# Despliegue de GLPI en k8s
```
# Creacion namespace
kubectl create namespace glpi && kubectl config set-context --current --namespace="glpi"
# Creación de secretos
kubectl create secret generic glpi-secrets --from-literal=MYSQL_RANDOM_ROOT_PASSWORD=yes --from-literal=MYSQL_USER='glpi_user' --from-literal=MYSQL_DATABASE='glpi_db' --from-literal=MYSQL_PASSWORD='verysecretpassword'
# Despliegue de la aplicación en k8s
kubectl apply -f glpi.yml -f persistent_volume_claim.yml -f db.yml
```