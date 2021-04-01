#/bin/bash

sudo apt update
sudo apt install -yq curl net-tools apt-transport-https gnupg2 ca-certificates software-properties-common git

sudo install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker 
#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
#sudo apt update
#sudo apt install -yq docker-ce docker-ce-cli containerd.io docker-compose

# add ssh user to docker group, so user can run docker commands if logging in to ssh
sudo usermod -aG docker ${ssh_user}

# install kubernetes components
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt update
sudo apt install -yq kubeadm kubectl kubelet

# install helm
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update
sudo apt install -yq helm

# init kubernetes to run locally
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
export KUBECONFIG=/etc/kubernetes/admin.conf

# create kube config for ssh user and root so they can run kubernetes commands, otherwise will get error that port (8080) is unavailable
sudo mkdir /home/${ssh_user}/.kube
sudo mkdir /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/${ssh_user}/.kube/config
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown ${ssh_user}:${ssh_user} /home/${ssh_user}/.kube
sudo chown ${ssh_user}:${ssh_user} /home/${ssh_user}/.kube/config

# start kubelet
sudo kubelet

# install flannel for networking.
# if pods are stuck pending, this may not have loaded correctly, re-run.
# kubectl describe nodes can show if there is an issue
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Remove master (control node) taint
# This allows pods to be scheduled on the master control node which is not allowed by default, used for 1-instance k8s
kubectl taint nodes --all node-role.kubernetes.io/master-
cd
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
