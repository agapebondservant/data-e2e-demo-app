#!/bin/bash

echo "Deploying Argo secrets..."

source .env

kubectl create secret docker-registry image-pull-secret \
        --docker-server=registry.tanzu.vmware.com \
        --docker-username=${DATA_E2E_VMWARE_REGISTRY_USERNAME} \
        --docker-password=${DATA_E2E_VMWARE_REGISTRY_PASSWORD} \
        --dry-run -o yaml | kubectl apply -n argo -f -

kubectl create secret docker-registry image-pull-secret-2 \
        --docker-server=registry.pivotal.io \
        --docker-username=${DATA_E2E_PIVOTAL_REGISTRY_USERNAME} \
        --docker-password=${DATA_E2E_PIVOTAL_REGISTRY_PASSWORD} \
        --dry-run -o yaml | kubectl apply -n argo -f -


kubectl create secret docker-registry image-pull-secret-3 \
        --docker-server=index.docker.io \
        --docker-username=${DATA_E2E_REGISTRY_USERNAME} \
        --docker-password=${DATA_E2E_REGISTRY_PASSWORD} \
        --dry-run -o yaml | kubectl apply -n argo -f -

kubectl create secret generic docker-config \
        --from-literal="config.json={\"auths\": {\"https://index.docker.io/v1/\": {\"auth\": \"$(echo -n $DATA_E2E_REGISTRY_USERNAME:$DATA_E2E_REGISTRY_PASSWORD|base64)\"}}}" \
        --dry-run -o yaml | kubectl apply -n argo -f -