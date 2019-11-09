curl -SLsf https://cli.openfaas.com | sudo sh

sudo echo export OPENFAAS_PREFIX="" >> ~/.bashrc # Populate with your Docker Hub username

sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

wget: wget -q -O - https://raw.githubusercontent.com/rancher/k3d/master/install.sh | bash

sudo export KUBECONFIG="$(k3d get-kubeconfig --name='k3s-default')" >> ~/.bashrc
. ~/.bashrc