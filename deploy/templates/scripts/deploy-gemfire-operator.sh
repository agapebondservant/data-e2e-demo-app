#!/bin/bash

echo "Installing Gemfire..."

source .env
helm uninstall gemfire-crd --namespace $GEMFIRE_NAMESPACE_NM || true
helm uninstall gemfire-operator --namespace $GEMFIRE_NAMESPACE_NM || true
kubectl delete ns $GEMFIRE_NAMESPACE_NM || true

kubectl create ns $GEMFIRE_NAMESPACE_NM
kubectl create secret docker-registry image-pull-secret \
        --namespace=gemfire-system \
        --docker-server=registry.tanzu.vmware.com \
        --docker-username=${DATA_E2E_VMWARE_REGISTRY_USERNAME} \
        --docker-password=${DATA_E2E_VMWARE_REGISTRY_PASSWORD} \
        --dry-run -o yaml | kubectl apply -n $GEMFIRE_NAMESPACE_NM -f -
helm install gemfire-crd oci://registry.tanzu.vmware.com/tanzu-gemfire-for-kubernetes/gemfire-crd \
    --version $GEMFIRE_VER \
    --namespace $GEMFIRE_NAMESPACE_NM \
    --set operatorReleaseName=gemfire-operator
helm install gemfire-operator oci://registry.tanzu.vmware.com/tanzu-gemfire-for-kubernetes/gemfire-operator \
    --version $GEMFIRE_VER \
    --namespace $GEMFIRE_NAMESPACE_NM

echo "Gemfire installed."