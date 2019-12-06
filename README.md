# Development setup

## vagrant with 3 VM (Tested)
Link: https://github.com/rootsongjc/kubernetes-vagrant-centos-cluster

**Comment out the below setting from install.sh, since this is only useful for users in China, and might have negative effect on users outside China.**

> <p> cat > /etc/docker/daemon.json "<<"EOF <br>
> { <br>
>  "registry-mirrors" : ["http://2595fda0.m.daocloud.io"] <br>
> } </p>

Make sure the cluster is ready by running
> kubectl get nodes

Check if all three nodes are ready


## Alternative- K3d (not tested)
***Setup***

> wget: wget -q -O - https://raw.githubusercontent.com/rancher/k3d/master/install.sh | bash \
sudo export KUBECONFIG="$(k3d get-kubeconfig --name='k3s-default')" >> ~/.bashrc \
. ~/.bashrc

create cluster

> k3d create

delete cluster

> k3d delete

# Quick start

Execute setup.sh
- install the helm cli
- install helm on the k8s cluster
- create two namespaces: openfaas and openfaas-fn
- install and setup openfaas
- create 3 persistent volumes
- start mongodb and redis
- host the Website
- get faas-cli ready to be used

**Detail description of each command is explained below**

# Openfaas setup
link: https://github.com/openfaas/workshop/blob/master/lab1b.md

## Kubernetes
link: https://kubernetes.io/docs/tasks/tools/install-kubectl/

***Install kubectl (not in the shell script)***
> sudo apt-get update && sudo apt-get install -y apt-transport-https \
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - \
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list \
sudo apt-get update && sudo apt-get install -y kubectl

## Helm
***Install the helm cli***
> curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

***Install helm on the k8s cluster***
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
>    --set queueWorker.ackWait="120s"<p>

* refer to link for configuration detail
* currently queueWorker.ackWait is set to 120 seconds to handle asynchronous long-running tasks (task can execute for 120 second before termination)

***Install faas-cli***
> curl -sLSf https://cli.openfaas.com | sudo sh

To connect faas-cli to the openfaas deployment

* For local development (k3d):
> kubectl port-forward svc/gateway -n openfaas 8080:8080 

* For vagrant:
> export OPENFAAS_URL="\<node ip\>:31112" (vagrant)

*node ip can be ip of any node in the cluster*

***PASSWORD***

This command logs in and saves a file to ~/.openfaas/config.yml
>PASSWORD=$(kubectl get secret -n openfaas basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode; echo) \
echo -n $PASSWORD | faas-cli login --username admin --password-stdin

***check faas-cli***

> faas-cli list

At this point, no function is being deployed, therefore it should return an empty list

# Deploy function to Openfaas
link: https://github.com/openfaas/workshop/blob/master/lab3.md

***Create a new template***
> faas-cli new --lang dockerfile \<function-name\> --prefix="your-docker-username-here"

>faas-cli up -f yolo.yml
* up combines build, push and deploy
* rename yml to stack.yml and use without -f

# Install helm dependencies
To install all dependencies listed in requirements.yaml
 > helm dep up . 

 # Redis and monggo

 ## Create 3 persistent volumes
 > kubectl apply -f sc.yaml 

 # Start helm chart
> helm install --name dev --namespace openfaas-fn db

faas-cli remove #name

helm del --purge #name

# portworx

helm install --debug --name test --set etcdEndPoint=etcd:http://172.17.8.101:2379,clusterName=mycluster ./helm/charts/portworx/
