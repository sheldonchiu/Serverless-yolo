# Development setup - vagrant is
Link: https://github.com/rootsongjc/kubernetes-vagrant-centos-cluster

# Openfaas setup
https://github.com/openfaas/workshop/blob/master/lab1b.md

## Kubernetes
link: https://kubernetes.io/docs/tasks/tools/install-kubectl/

> sudo apt-get update && sudo apt-get install -y apt-transport-https \
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - \
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list \
sudo apt-get update && sudo apt-get install -y kubectl

## K3d
***Setup***

> wget: wget -q -O - https://raw.githubusercontent.com/rancher/k3d/master/install.sh | bash \
sudo export KUBECONFIG="$(k3d get-kubeconfig --name='k3s-default')" >> ~/.bashrc \
. ~/.bashrc

create cluster

> k3d create

delete cluster

> k3d delete

## Helm
***Setup***

> curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

> <p>kubectl -n kube-system create sa tiller \ <br>
>  && kubectl create clusterrolebinding tiller \ <br>
>  --clusterrole cluster-admin \ <br>
>  --serviceaccount=kube-system:tiller <p>

> helm init --skip-refresh --upgrade --service-account tiller

## Cluster setup

link: https://github.com/openfaas/faas-netes/blob/master/chart/openfaas/README.md

***Create namespace***

> kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml

> helm repo add openfaas https://openfaas.github.io/faas-netes/

***Generate a random password***

> PASSWORD=$(head -c 12 /dev/urandom | shasum| cut -d' ' -f1)

> <p> kubectl -n openfaas create secret generic basic-auth \ <br>
> --from-literal=basic-auth-user=admin \ <br>
> --from-literal=basic-auth-password="$PASSWORD" <p>

> <p> helm repo update \ <br>
> && helm upgrade openfaas --install openfaas/openfaas \ <br>
>    --namespace openfaas  \ <br>
>    --set basic_auth=true \ <br>
>    --set functionNamespace=openfaas-fn \ <br>
>    --set queueWorker.replicas=3 \ <br>
>    --set queueWorker.ackwait="120s"<p>

* refer to link for configuration detail

For local development, expose the port with this

> kubectl port-forward svc/gateway -n openfaas 8080:8080

or

> export OPENFAAS_URL="\<node ip\>:31112"

***To obtain the ip***
> kubectl get pods -n openfaas -o yaml | grep hostIP

***PASSWORD***

This command logs in and saves a file to ~/.openfaas/config.yml
>PASSWORD=$(kubectl get secret -n openfaas basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode; echo) \
echo -n $PASSWORD | faas-cli login --username admin --password-stdin

***check faas***

> faas-cli list

# Functions

link: https://github.com/openfaas/workshop/blob/master/lab3.md

> faas-cli new --lang dockerfile yolo --prefix="your-docker-username-here"

>faas-cli up -f yolo.yml

* rename yml to stack.yml and use without -f

# Access the pod
Same as OPENFAAS_URL

e.g 172.19.0.2

# Install helm dependencies
To install all dependencies listed in requirements.yaml
 > helm dep up . 

 http://grafana.sheldon.io/

 https://172.17.8.101:8443/

 # redis and monggo

 ## PV
 > kubectl apply -f sc.yaml 

 # Start helm chart
> helm install --name dev --namespace openfaas-fn test

faas-cli remove #name

helm del --purge #name

# portworx

helm install --debug --name test --set etcdEndPoint=etcd:http://172.17.8.101:2379,clusterName=mycluster ./helm/charts/portworx/
