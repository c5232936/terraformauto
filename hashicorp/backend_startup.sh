cd /opt
mkdir HCL_Commerce

sudo chmod 777 /opt/HCL_Commerce
cd /opt/HCL_Commerce
wget --ftp-user "ronny.shmoel@circuitcity.com" --ftp-password 'X^r*99Yd$X&n' "https://hclsoftware.flexnetoperations.com/flexnet/operationsportal/entitledDownloadFile.action?downloadPkgId=HCL_Commerce_Helm_Charts_Version_9.1.4.0"
mv 'HCL-Commerce-Helm-Charts-9.1.4.0.bundle?ftpRequestID=2479809713&server=download.flexnetoperations.com&dtm=DTM20210325083428MjI3Mjg2MjUw&authparam=1616686468_d0650ea953ec5e1329ec00b7f8a19bb6&ext=.bundle' HCL-Commerce-Helm-Charts-9.1.4.0.bundle

git clone HCL_Commerce_Helm_Charts_9.1.4.0.bundle 

# Create required namespaces
kubectl create ns vault
kubectl create ns commerce
kubectl create ns elastic
kubectl create ns nginx
kubectl create ns zookeeper
kubectl create ns redis



# use helm to install vault-consul (2 pods) with default values
cd /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.4.0/hcl-commerce-vaultconsul-helmchart/stable/hcl-commerce-vaultconsul
helm install vault ./ -n vault -f values.yaml



# Create persistent volumes and claims for elastic search/nifi
cd /opt/conf

kubectl create -f elastic-pvc.yaml
kubectl create -f nifi-pvc.yaml


#Add helm repos
sudo helm repo add elastic https://helm.elastic.co
helm repo add bitnami https://charts.bitnami.com/bitnami



sudo helm repo update
cd /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.4.0/hcl-commerce-helmchart/sample_values

# Install elastic search
sudo helm install elasticsearch elastic/elasticsearch -n elastic -f elasticsearch-values.yaml

# Install zookeeper
sudo helm install zookeeper -n zookeeper bitnami/zookeeper -f zookeeper-values.yaml

# Install redis
sudo helm install my-redis bitnami/redis -n redis -f redis-values.yaml --set master.disableCommands=""



#nginx settings - use NodePort,  set permanent ports
#sudo sed -i -e 's|type: LoadBalancer|type: NodePort|' /opt/HCL_Commerce/kubernetes-ingress/deployments/helm-chart/values.yaml
#sudo sed -i -e '226s|nodePort: ""|nodePort: "30080"|' /opt/HCL_Commerce/kubernetes-ingress/deployments/helm-chart/values.yaml
#sudo sed -i -e '239s|nodePort: ""|nodePort: "30443"|' /opt/HCL_Commerce/kubernetes-ingress/deployments/helm-chart/values.yaml

#helm install nginx-ingress . -n nginx

#rbac settings
sudo sed -i -e 's|<namespace>|commerce|g' /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.5.0/hcl-commerce-helmchart/stable/hcl-commerce/rbac.yaml

#hcl commerce settings
#sudo sed -i -e 's|license: not_accepted|license: accept|' /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.5.0/hcl-commerce-helmchart/stable/hcl-commerce/values.yaml
#sudo sed -i -e 's|environmentType: auth|environmentType: share|' /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.5.0/hcl-commerce-helmchart/stable/hcl-commerce/values.yaml
#sudo sed -i -e 's|imageRepo: my-docker-registry.io:5000/|imageRepo: localhost:5000/|' /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.5.0/hcl-commerce-helmchart/stable/hcl-commerce/values.yaml
#sudo sed -i -e 's|tag: v9-latest|tag: 9.1.5.0|g' /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.5.0/hcl-commerce-helmchart/stable/hcl-commerce/values.yaml
#sudo sed -i -e 's|tag: 2.1.0|tag: 9.1.5.0|' /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.5.0/hcl-commerce-helmchart/stable/hcl-commerce/values.yaml
#sudo sed -i -e 's|autoCreate: true|autoCreate: false|' /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.5.0/hcl-commerce-helmchart/stable/hcl-commerce/values.yaml
#sudo sed -i -e 's|replaceExist: true|replaceExist: false|' /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.5.0/hcl-commerce-helmchart/stable/hcl-commerce/values.yaml
#sudo sed -i -e '588s|existingClaim: ""|existingClaim: "demo-qa-share-demoqa-nifi-pvc"|' /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.5.0/hcl-commerce-helmchart/stable/hcl-commerce/values.yaml
#sudo sed -i -e 's|spiUserPwdAes:|spiUserPwdAes: eNdqdvMAUGRUbiuqadvrQfMELjNScudSp5CBWQ8L6aw=|' /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.5.0/hcl-commerce-helmchart/stable/hcl-commerce/values.yaml
#sudo sed -i -e 's|spiUserPwdBase64:|spiUserPwdBase64: c3BpdXNlcjpwYXNzdzByZA==|' /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.5.0/hcl-commerce-helmchart/stable/hcl-commerce/values.yaml
#sudo sed -i -e 's|dataIngressEnabled: false|dataIngressEnabled: true|' /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.5.0/hcl-commerce-helmchart/stable/hcl-commerce/values.yaml
#sudo sed -i -e '520s|enabled: true|enabled: false|' /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.5.0/hcl-commerce-helmchart/stable/hcl-commerce/values.yaml
#sudo sed -i -e '683s|enabled: false|enabled: true|' /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.5.0/hcl-commerce-helmchart/stable/hcl-commerce/values.yaml

sudo docker start registry

cd /opt/HCL_Commerce/HCL_Commerce_Helm_Charts_9.1.4.0/hcl-commerce-helmchart/stable/hcl-commerce

kubectl apply -f rbac.yaml

helm install demo-qa-share ./ -n commerce --set common.environmentType=share
#helm install demo-qa-auth ./ -n commerce --set common.environmentType=auth

# GET Server External IP from command line and replace IP in following command
#export EXT_IP="$(curl -H 'Metadata-Flavor: Google' http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)"
#export NGINX_STRING="'{\"spec\": {\"type\": \"LoadBalancer\", \"externalIPs\":[\"$EXT_IP\"]}}'"
#kubectl patch svc nginx-ingress-nginx-ingress -n nginx -p NGINX_STRING

#build index
#export TS_APP_PORT=
#curl -k -s -X POST -u spiuser:passw0rd https://$EXT_IP:$TS_APP_PORT/wcs/resources/admin/index/dataImport/build?connectorId=auth.reindex&storeId=715839984

#helm install demo-qa-live ./ -n commerce --set common.environmentType=live

