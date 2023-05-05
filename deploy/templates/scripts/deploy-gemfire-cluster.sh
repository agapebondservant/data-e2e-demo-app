#!/bin/bash

echo "Deploying Gemfire cluster..."

source .env

export DEMO_GEMFIRE_NS=$1

kubectl create secret docker-registry image-pull-secret \
        --docker-server=registry.tanzu.vmware.com \
        --docker-username=${DATA_E2E_VMWARE_REGISTRY_USERNAME} \
        --docker-password=${DATA_E2E_VMWARE_REGISTRY_PASSWORD} \
        --dry-run -o yaml | kubectl apply -n $DEMO_GEMFIRE_NS -f -

kubectl create secret docker-registry image-pull-secret-2 \
        --docker-server=registry.pivotal.io \
        --docker-username=${DATA_E2E_PIVOTAL_REGISTRY_USERNAME} \
        --docker-password=${DATA_E2E_PIVOTAL_REGISTRY_PASSWORD} \
        --dry-run -o yaml | kubectl apply -n $DEMO_GEMFIRE_NS -f -


kubectl create secret docker-registry image-pull-secret-3 \
        --docker-server=index.docker.io \
        --docker-username=${DATA_E2E_REGISTRY_USERNAME} \
        --docker-password=${DATA_E2E_REGISTRY_PASSWORD} \
        --dry-run -o yaml | kubectl apply -n $DEMO_GEMFIRE_NS -f -

ytt -f deploy/templates/demo-data/gemfire-cluster.yaml -f deploy/templates/demo-data/values.yaml | kubectl apply -n $DEMO_GEMFIRE_NS -f -

echo "Gemfire cluster deployed."