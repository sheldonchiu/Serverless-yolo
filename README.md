# Development setup

## vagrant with 3 VM (Tested)
Link: https://github.com/rootsongjc/kubernetes-vagrant-centos-cluster

**Comment out the below setting from install.sh, since this is only useful for users in China, and might have negative effect on users outside China.**

> <p> cat > /etc/docker/daemon.json "<<"EOF <br>
> { <br>
>  "registry-mirrors" : ["http://2595fda0.m.daocloud.io"] <br>
> } </p>

Make sure the cluster is ready by running
```bash
kubectl get nodes
```

Check if all three nodes are ready

Kubernetes dashboard URL: https://172.17.8.101:8443

## Alternative- K3d (not tested)
***Setup***
```bash
wget -q -O - https://raw.githubusercontent.com/rancher/k3d/master/install.sh | bash
sudo export KUBECONFIG="$(k3d get-kubeconfig --name='k3s-default')" >> ~/.bashrc
. ~/.bashrc
```
create cluster
```bash
k3d create
```
delete cluster
```bash
k3d delete
```
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
```bash
sudo apt-get update && sudo apt-get install -y apt-transport-https 
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list 
sudo apt-get update && sudo apt-get install -y kubectl
```
## Helm
***Install the helm cli***
> curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

***Install helm on the k8s cluster***
```bash
kubectl -n kube-system create sa tiller \
&& kubectl create clusterrolebinding tiller \ 
--clusterrole cluster-admin \
--serviceaccount=kube-system:tiller
```
```bash
helm init --skip-refresh --upgrade --service-account tiller
```
## Cluster setup
link: https://github.com/openfaas/faas-netes/blob/master/chart/openfaas/README.md

***Create namespace***
```bash
kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
```
```bash
helm repo add openfaas https://openfaas.github.io/faas-netes/
```

***Generate a random password***
```bash
PASSWORD=$(head -c 12 /dev/urandom | shasum| cut -d' ' -f1)
```
```bash
kubectl -n openfaas create secret generic basic-auth \
from-literal=basic-auth-user=admin \
from-literal=basic-auth-password="$PASSWORD"
```
```bash
helm repo update \
&& helm upgrade openfaas --install openfaas/openfaas \
--namespace openfaas \
-f openfaas.yaml
```
* refer to link for configuration detail
* currently queueWorker.ackWait is set to 120 seconds to handle asynchronous long-running tasks (task can execute for 120 second before termination)

***Install faas-cli***
```bash
curl -sLSf https://cli.openfaas.com | sudo sh
```
To connect faas-cli to the openfaas deployment

* For local development (k3d):
```bash
kubectl port-forward svc/gateway -n openfaas 8080:8080 
```
* For vagrant:
```bash
export OPENFAAS_URL="<node ip>:31112"
```
*node ip can be ip of any node in the cluster*

***PASSWORD***

This command logs in and saves a file to ~/.openfaas/config.yml
```bash
PASSWORD=$(kubectl get secret -n openfaas basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode; echo)
echo -n $PASSWORD | faas-cli login --username admin --password-stdin
```
***check faas-cli***
```bash
faas-cli list
```
At this point, no function is being deployed, therefore it should return an empty list

 # Redis and mongoDB

***Create 3 persistent volumes***
```bash
kubectl apply -f sc.yaml 
```
 ***Start helm chart***
 ```bash
helm install --name dev --namespace openfaas-fn db
```
***To remove the installed chart***
```bash
helm del --purge <name>
```
# Deploy function to Openfaas
link: https://github.com/openfaas/workshop/blob/master/lab3.md

***Create a new template***
```bash
faas-cli new --lang dockerfile <function-name> --prefix="your-docker-username-here"
```
```bash
faas-cli up -f yolo.yml
```
* up combines build, push and deploy
* rename yml to stack.yml and use without -f

***To remove function***
```bash
> faas-cli remove <function-name>
```
# Visit the website

Append the following line to /etc/hosts
> 172.17.8.102  test.comp4651.io

The hostname is configured in web.yml, using traefik ingress

Visit test.comp4651.io

<!-- # portworx

helm install --debug --name test --set etcdEndPoint=etcd:http://172.17.8.101:2379,clusterName=mycluster ./helm/charts/portworx/ -->

# Debug

***Connect to Redis***
```bash
kubectl exec -n openfaas-fn -it dev-redis-master-0 -- /bin/bash
```
Run redis-cli inside the pod

***Connect to MongoDB***
```bash
kubectl exec -n openfaas-fn -it <name-of-mongo> -- /bin/bash
```
find the pod name using
```bash
kubectl get pods -n openfaas-fn
```
It should starts with dev-mongo

# OpenFaas auto-scaling using K8s HPAv2
```bash
kubectl autoscale deployment -n openfaas-fn \
  <function-name> \
  --cpu-percent=150 \
  --min=1 \
  --max=3
  ```

  # Deploy on Google Kubernetes Engine (gke branch)

## Setup

***node pools***
* default-pool
* openfaas

Since yolo detection usually consumes up to 90% cpu utilization and more than 500Mb of memory, a new node pool with high performance CPU is needed to isolate it from other tasks.

To minimize the cost, auto-scaling can be applied to the openfaas node pool.