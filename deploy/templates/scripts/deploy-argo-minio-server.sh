source .env

kubectl delete ns ${MINIO_BUCKET_NAMESPACE}

envsubst < deploy/templates/demo-minio/minio-http-proxy.in.yaml > deploy/templates/demo-minio/minio-http-proxy.yaml

helm repo add minio-legacy https://helm.min.io/

kubectl create ns ${MINIO_BUCKET_NAMESPACE}

helm install --set resources.requests.memory=1.5Gi,auth.rootUser=minio,ingress.enabled=true,ingress.hostname="minio-argo.${DATA_E2E_FQDN_DOMAIN}" --namespace ${MINIO_BUCKET_NAMESPACE} minio oci://registry-1.docker.io/bitnamicharts/minio --wait

kubectl apply -f deploy/templates/demo-minio/minio-http-proxy.yaml --namespace ${MINIO_BUCKET_NAMESPACE}

export MINIO_ARGO_ACCESS_KEY_ID=$(kubectl get secret minio -o jsonpath="{.data.root-user}" -n ${MINIO_BUCKET_NAMESPACE}| base64 --decode)

export MINIO_ARGO_SECRET_ACCESS_KEY=$(kubectl get secret minio -o jsonpath="{.data.root-password}" -n ${MINIO_BUCKET_NAMESPACE}| base64 --decode)

sleep 5

kubectl apply -f deploy/templates/demo-minio/minio-secret-exporter.yaml -n ${MINIO_BUCKET_NAMESPACE}

kubectl apply -f deploy/templates/demo-minio/minio-secret-importer.yaml -n argo

mc config host add --insecure data-e2e-minio-argo http://minio-argo.${DATA_E2E_FQDN_DOMAIN} ${MINIO_ARGO_ACCESS_KEY_ID} ${MINIO_ARGO_SECRET_ACCESS_KEY}

mc mb --insecure -p data-e2e-minio-argo/demo && mc policy --insecure set public data-e2e-minio-argo/demo