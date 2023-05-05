#!/bin/bash

echo "Deleting any pre-existing RabbitMQ install..."
kubectl delete all --all -nrabbitmq-system || true
kapp delete -a tanzu-rabbitmq-repo -y -nrabbitmq-system || true
kapp delete -a tanzu-rabbitmq -y -nrabbitmq-system || true
export RABBIT_KAPP_INST=$(kubectl get bindings.rabbitmq.com -ojson | jq '.metadata.labels["kapp.k14s.io/app"]' | tr -d '"')
kubectl get validatingwebhookconfiguration -l kapp.k14s.io/app=$RABBIT_KAPP_INST -o name | xargs -r kubectl delete
kubectl get clusterrolebinding -l kapp.k14s.io/app=$RABBIT_KAPP_INST -o name | xargs -r kubectl delete
kubectl get clusterrole -l kapp.k14s.io/app=$RABBIT_KAPP_INST -o name | xargs -r kubectl delete
for n in $(kubectl get crd -o name | grep 'rabbitmq.com'); do
  kubectl get $n -o name | xargs -r kubectl delete
done
# kubectl delete ns rabbitmq-system

sleep 10

echo "Installing RabbitMQ..."

source .env
kubectl create ns rabbitmq-system --dry-run -o yaml | kubectl apply -f -
kubectl apply -f deploy/templates/demo-data/rabbitmq-operator-rbac.yaml -n rabbitmq-system
kubectl create clusterrolebinding tanzu-rabbitmq-crd-install-binding \
    --clusterrole=tanzu-rabbitmq-crd-install \
    --serviceaccount=rabbitmq-system:default -n rabbitmq-system \
    --dry-run -o yaml | kubectl apply -n rabbitmq-system -f -

kubectl create secret docker-registry image-pull-secret --namespace=rabbitmq-system \
--docker-username=${DATA_E2E_REGISTRY_USERNAME} \
--docker-password=${DATA_E2E_REGISTRY_PASSWORD} \
--dry-run -o yaml | kubectl apply -f -

kubectl apply -f deploy/templates/demo-data/rabbitmq-operator-secretexport-main.yaml

kapp deploy -a tanzu-rabbitmq-repo -f deploy/templates/demo-data/rabbitmq-operator-packagerepository.yaml -y -nrabbitmq-system
kapp deploy -a tanzu-rabbitmq -f deploy/templates/demo-data/rabbitmq-operator-packageinstall.yaml -y -nrabbitmq-system

echo "RabbitMQ installed."