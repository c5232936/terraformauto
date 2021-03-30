git clone https://github.com/c5232936/terraformauto

# Create required namespaces
kubectl create ns vault
kubectl create ns commerce
kubectl create ns elastic
kubectl create ns nginx
kubectl create ns zookeeper
kubectl create ns redis



# use helm to install vault-consul (2 pods) with default values
cd terraformauto/HCL_Commerce_Helm_Charts_9.1.4.0/hcl-commerce-vaultconsul-helmchart/stable/hcl-commerce-vaultconsul
helm install vault ./ -n vault -f values.yaml



# Create persistent volumes and claims for elastic search/nifi
cd
cd terraformauto/HCL-Commerce-Helm-Charts-9.1.4.0/hcl-commerce-helmchart/sample_values
kubectl create -f elastic-pvc.yaml
kubectl create -f nifi-pvc.yaml


#Add helm repos
sudo helm repo add elastic https://helm.elastic.co
helm repo add bitnami https://charts.bitnami.com/bitnami


sudo helm repo update


# Install elastic search
sudo helm install elasticsearch elastic/elasticsearch -n elastic -f elasticsearch-values.yaml

# Install zookeeper
sudo helm install zookeeper -n zookeeper bitnami/zookeeper -f zookeeper-values.yaml

# Install redis
sudo helm install my-redis bitnami/redis -n redis -f redis-values.yaml --set master.disableCommands=""
cd
cd terraformauto/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.4.0/hcl-commerce-helmchart/stable/hcl-commerce

kubectl apply -f rbac.yaml

helm install demo-qa-share ./ -n commerce --set common.environmentType=share
