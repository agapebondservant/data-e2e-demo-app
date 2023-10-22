source .env

kubectl delete ns ${MINIO_BUCKET_NAMESPACE}

envsubst < deploy/templates/demo-minio/minio-http-proxy.in.yaml > deploy/templates/demo-minio/minio-http-proxy.yaml

helm repo add minio-legacy https://helm.min.io/

kubectl create ns ${MINIO_BUCKET_NAMESPACE}

helm install --set resources.requests.memory=1.5Gi,tls.enabled=false --namespace ${MINIO_BUCKET_NAMESPACE} minio minio-legacy/minio --set service.type=LoadBalancer --set service.port=9000

kubectl apply -f deploy/templates/demo-minio/minio-http-proxy.yaml --namespace ${MINIO_BUCKET_NAMESPACE}

export MINIO_ARGO_ACCESS_KEY_ID=$(kubectl get secret minio -o jsonpath="{.data.accesskey}" -n ${MINIO_BUCKET_NAMESPACE}| base64 --decode)

export MINIO_ARGO_SECRET_ACCESS_KEY=$(kubectl get secret minio -o jsonpath="{.data.secretkey}" -n ${MINIO_BUCKET_NAMESPACE}| base64 --decode)

kubectl wait --for=condition=Ready pod -l app=minio -n ${MINIO_BUCKET_NAMESPACE} --timeout=120s

sleep 5

kubectl apply -f deploy/templates/demo-minio/minio-secret-exporter.yaml -n ${MINIO_BUCKET_NAMESPACE}

kubectl apply -f deploy/templates/demo-minio/minio-secret-importer.yaml -n argo

mc config host add --insecure data-e2e-minio-argo http://${ARGO_S3_ENDPOINT_FQDN} ${MINIO_ARGO_ACCESS_KEY_ID} ${MINIO_ARGO_SECRET_ACCESS_KEY}

mc mb --insecure -p data-e2e-minio-argo/demo && mc policy --insecure set public data-e2e-minio-argo/demo