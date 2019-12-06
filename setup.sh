#helm
if ! [ -x "$(command -v helm)" ]; then
  curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
fi
kubectl -n kube-system create sa tiller \
&& kubectl create clusterrolebinding tiller \
--clusterrole cluster-admin \
--serviceaccount=kube-system:tiller 

helm init --skip-refresh --upgrade --service-account tiller

#Create namespace
kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
helm repo add openfaas https://openfaas.github.io/faas-netes/

#password
PASSWORD=$(head -c 12 /dev/urandom | shasum| cut -d' ' -f1)

kubectl -n openfaas create secret generic basic-auth \
--from-literal=basic-auth-user=admin \
--from-literal=basic-auth-password="$PASSWORD" 

while [[ $(kubectl get pods -n kube-system | grep tiller) != *"1/1"* ]]; 
do
    sleep 1
done

helm repo update \
&& helm upgrade openfaas --install openfaas/openfaas \
--namespace openfaas \
--set basic_auth=true \
--set functionNamespace=openfaas-fn \
--set queueWorker.replicas=3 \
--set queueWorker.ackWait="120s"

#install infra
kubectl apply -f sc.yaml
helm install --name dev --namespace openfaas-fn db
kubectl apply -f web.yml

while [[ $(kubectl get pods -n openfaas | grep gateway) != *"Running"* ]]; 
do
    sleep 1
done

sleep 2

echo -n $PASSWORD | faas-cli login --username admin --password-stdin
faas-cli up -f yolo.yml