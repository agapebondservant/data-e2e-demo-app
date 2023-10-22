# VMWARE DATA DEMO APP - Installing on TKG/TAP

1. [Pre-requisites for installing on Kubernetes](#kubernetes)
2. [Set up Gemfire and RabbitMQ](#gemfire-and-rabbit)
3. [Set up ETL](#etl)
4. [Set up frontend and backend apps](#frontend-backend-apps)
5. [TODO: Installing on TAP](#tap)
6. [TODO: Integrating ML/MLOps](#mlops)
7. [Alternative: Installing on Workstation](#workstation)

<div style="color: #ceddee;">
<hr/>
<b><u>CREDITS</u></b><br/>
This was forked from the <b>Anomaly Detection demo</b> originally presented at <a href="https://vmware-explore-in.cventevents.com/event/1afa043a-2293-433d-9d63-85ff52ba8584/websitePage:f980d165-31f2-4d39-af64-2dfc5826a836" target="_blank">VMExplore India 2023</a>,
and leverages the source code from their hard work.<br/>
To learn more, please see the original git repository <a href="https://gitlab.eng.vmware.com/nn2/vmware-explore-demo-app.git" target="_blank">here</a>.
<hr/>
</div>

# Deploying Accelerator

* Install App Accelerator: (see https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-cert-mgr-contour-fcd-install-cert-mgr.html)
```
tanzu package available list accelerator.apps.tanzu.vmware.com --namespace tap-install
tanzu package install accelerator -p accelerator.apps.tanzu.vmware.com -v 1.0.1 -n tap-install -f resources/argo-workflows-accelerator.git.yaml
Verify that package is running: tanzu package installed get accelerator -n tap-install
Get the IP address for the App Accelerator API: kubectl get service -n accelerator-system
```

Publish Accelerator:
```
tanzu plugin install --local <path-to-tanzu-cli> all
tanzu acc create realtime-analytics-acc --git-repository https://github.com/agapebondservant/data-e2e-demo-app.git --git-branch main
```

## Pre-requisites for installing on Kubernetes <a name=kubernetes>
1. Make sure you set up the following pre-requisites:
- [ ] Kubernetes 1.23+
- [ ] Maven (supported version)
- [ ] Project Contour
- [ ] Environment file (.env - should be located at project root; use .env-sample as a guide)
- [ ] values.yaml files (must create `deploy/templates/demo-ui/values.yaml` and `deploy/templates/demo-data/values.yaml`; use values-template.yaml as a guide)
- [ ] psql client
- [ ] Spring Cloud Data Flow
- [ ] DataHub

2. Prepare manifest files:
```
source .env
for orig in `find . -name "*.in.*" -type f`; do
  target=$(echo $orig | sed 's/\.in//')
  envsubst < $orig > $target
  grep -qxF $target .gitignore || echo $target >> .gitignore
done
```

3. (For TAP 1.6+) Deploy additional ClusterBuilders:
```
kubectl apply -f deploy/templates/demo-cluster/
```

4. Deploy Argo Events:
```
kubectl create namespace argo-events
kubectl apply -f demo-ml/argo/install-argo-events.yaml 
kubectl apply -f demo-ml/argo/install-argo-events-validatinghook.yaml 
```

5. Deploy Minio server for Argo:
```
deploy/templates/scripts/deploy-argo-minio-server.sh
```

6. Deploy additional secrets:
```
deploy/templates/scripts/deploy-additional-secrets.sh
```

### Set up Gemfire and RabbitMQ <a name=gemfire-and-rabbit>
1. Create target namespace for backing services:
```
source .env
export DEMO_NS=anomaly-ns # or preferred name
kubectl create ns $DEMO_NS
```

2. Deploy Gemfire operator (if it has not already been installed):
```
deploy/templates/scripts/deploy-gemfire-operator.sh
```

3. Verify that the deployment was successful:
```
watch kubectl get all -n $GEMFIRE_NAMESPACE_NM
```

4. Deploy Gemfire cluster:
```
deploy/templates/scripts/deploy-gemfire-cluster.sh $DEMO_NS
```

5. Verify that the deployment was successful:
```
watch kubectl get all -n $DEMO_NS
```

6. Create Gemfire regions:
```
kubectl exec -it gfanomaly-server-0 -n $DEMO_NS -- gfsh -e "connect --locator=gfanomaly-locator-0.gfanomaly-locator.anomaly-ns.svc.cluster.local[10334]" -e "create region --name=mds-region --type=PARTITION --enable-statistics --entry-idle-time-expiration=300" -e "create region --name=mds-region-greenplum --type=PARTITION --enable-statistics --entry-idle-time-expiration=300" -e "create region --name=mds-region-greenplum-snapshot --type=PARTITION --eviction-entry-count=2 --eviction-action=overflow-to-disk"
```

7. Deploy RabbitMQ operator (if it has not already been installed):
```
deploy/templates/scripts/deploy-rabbit-operator.sh
```

8. Verify that the deployment was successful:
```
tanzu package installed get tanzu-rabbitmq -nrabbitmq-system
```

9. Deploy RabbitMQ cluster and queue:
```
deploy/templates/scripts/deploy-rabbit-cluster.sh $DEMO_NS
```

10. Verify that the deployment was successful:
```
watch kubectl get all -n $DEMO_NS
```

11. Access endpoints:
  * For Gemfire Pulse endpoint: `gfanomaly-locator.YOUR-FQDN-DOMAIN/pulse` (default credentials: admin/admin)
  * For Gemfire REST API: `gfanomaly-server.YOUR-FQDN-DOMAIN/gemfire-api/v1`
  * For RabbitMQ Management endpoint: `rmqanomaly.YOUR-FQDN-DOMAIN`
  * Get login credentials for RabbitMQ Management console:
```
kubectl get secret rmqanomaly-default-user -o jsonpath="{.data.default_user\.conf}" -n $DEMO_NS | base64 --decode
```

* To delete the Gemfire and RabbitMQ clusters:
```
kubectl delete all --all -n $DEMO_NS
kubectl delete pvc --all -n $DEMO_NS
kubectl delete ns $DEMO_NS
```

### Set up frontend and backend apps <a name=frontend-backend-apps>

1. Build frontend container image dependency (if it has not already been built, or if changes were made to the code):
```
cd demo-ui
docker build -t $DATA_E2E_REGISTRY_USERNAME/demo-ui-anomaly .
docker push $DATA_E2E_REGISTRY_USERNAME/demo-ui-anomaly
cd -
```

2. Build backend container image dependency (if it has not already been built, or if changes were made to the code):
```
cd demo
mvn package
docker build -t $DATA_E2E_REGISTRY_USERNAME/demo-app-anomaly .
docker push $DATA_E2E_REGISTRY_USERNAME/demo-app-anomaly
cd -
```

3. Set up app dependencies and deploy the backend and frontend app:
```
source .env
kubectl create ns vmware-explore
kubectl create secret docker-registry image-pull-secret -n vmware-explore --docker-server=index.docker.io --docker-username=$DATA_E2E_REGISTRY_USERNAME --docker-password=$DATA_E2E_REGISTRY_PASSWORD
ytt -f deploy/templates/demo-ui/ | kubectl apply -f -
kubectl apply -f deploy/templates/demo-app/
```

4. Verify that the backend and frontend deployments show "Ready" status:
```
watch kubectl get all -n vmware-explore
```

5. View backend app logs:
```
kubectl logs -l app=demo-app -n vmware-explore
```

6. View frontend app logs:
```
{ kubectl logs -l app=demo-ui -n vmware-explore & \
kubectl exec -it $(kubectl get pod -oname -l app=demo-ui -n vmware-explore) -n vmware-explore -- cat /opt/bitnami/nginx/log/nginx/nginx_access.log; }
```

7. Access endpoints:
  * For UI: `demo-ui.YOUR-FQDN-DOMAIN`

  * To delete the frontend and backend apps:
```
ytt -f deploy/templates/demo-ui/ | kubectl delete -f -
kubectl delete -f deploy/templates/demo-app/
kubectl delete ns vmware-explore
```

### Set up ETL <a name=etl>
1. Install Spring Cloud Data Flow:
```
deploy/templates/scripts/setup-scdf-1.3.sh
```

2. Register additional starter apps: (see Spring Cloud Data Flow docs)
   
sink.gemfire=docker:springcloudstream/gemfire-sink-rabbit:2.1.6.RELEASE
source.gemfire=docker:springcloudstream/gemfire-source-rabbit:2.1.6.RELEASE
source.gemfire-cq=docker:springcloudstream/gemfire-cq-source-rabbit:2.1.6.RELEASE
source.trigger=https://repo.spring.io/artifactory/release/org/springframework/cloud/stream/app/trigger-source-rabbit/2.1.4.RELEASE/trigger-source-rabbit-2.1.4.RELEASE.jar

3. Set up Greenplum password:
```
export DATA_E2E_ML_TRAINING_DB_PASSWORD=<enter password>
```

4. Deploy Madlib training function in Greenplum (if not already deployed - one-time op):
```
export DATA_E2E_ML_TRAINING_DB_PASSWORD=<enter password>
export PSQL_CONNECT_STR=postgresql://${DATA_E2E_ML_TRAINING_DB_USERNAME}:${DATA_E2E_ML_TRAINING_DB_PASSWORD}@${DATA_E2E_ML_TRAINING_DB_HOST}:${DATA_E2E_ML_TRAINING_DB_PORT}/${DATA_E2E_ML_TRAINING_DB_DATABASE}?sslmode=require
psql ${PSQL_CONNECT_STR} -f demo-ml/resources/sql/random_forest_madlib_training.sql
```

5. Set up Greenplum-Gemfire pipeline by copying the output of the following:
```
export DATA_E2E_ML_TRAINING_DB_PASSWORD=<enter password>
echo -e greenplum-inference=jdbc --spring.datasource.url=\"jdbc:postgresql://${DATA_E2E_ML_TRAINING_DB_HOST}:5432/${DATA_E2E_ML_TRAINING_DB_DATABASE}\" --spring.datasource.username=\"gpadmin\" --spring.datasource.password=\"${DATA_E2E_ML_TRAINING_DB_PASSWORD}\" --spring.cloud.stream.poller.cron=\"0 0 0 \* \* \*\" --jdbc.supplier.query=\"select row_to_json\(randomforest\) from \(SELECT id, time_passed, amount, latitude, longitude, is_fraud_flag, training_run_timestamp, cls_weight FROM rf_credit_card_inferences_vw limit 1000 \) randomforest\" \| transform --spel.function.expression=\"#jsonPath\(payload, \'$.row_to_json.value\'\)\"  \| gemfire --gemfire.pool.host-addresses=\"gfanomaly-locator-0.gfanomaly-locator.anomaly-ns.svc.cluster.local:10334\" --gemfire.region.regionName=\"mds-region-greenplum\" --gemfire.sink.json=\"true\" --gemfire.sink.keyExpression=\"payload.getField\(\'id\'\)\" \\n\
greenplum-inference-monitor=jdbc --spring.datasource.url=\"jdbc:postgresql://${DATA_E2E_ML_TRAINING_DB_HOST}:5432/${DATA_E2E_ML_TRAINING_DB_DATABASE}\" --spring.datasource.username=\"gpadmin\" --spring.datasource.password=\"${DATA_E2E_ML_TRAINING_DB_PASSWORD}\" --spring.cloud.stream.poller.cron=\"0 0 0 \* \* \*\" --jdbc.supplier.query=\"select row_to_json\(randomforest\) from \(SELECT max\(training_run_timestamp\) as snapshot FROM rf_credit_card_inferences_vw\) randomforest\" \| transform --spel.function.expression=\"#jsonPath\(payload, \'$.row_to_json.value\'\)\"  \| gemfire --gemfire.pool.host-addresses=\"gfanomaly-locator-0.gfanomaly-locator.anomaly-ns.svc.cluster.local:10334\" --gemfire.region.regionName=\"mds-region-greenplum-snapshot\" --gemfire.sink.json=\"true\" --gemfire.sink.keyExpression=\"payload.getField\(\'snapshot\'\)\"

```

### Integrating ML/MLOps <a name=mlops>
1. Load training data into Greenplum:
```
export DATA_E2E_ML_TRAINING_DB_PASSWORD=<enter password>
export PSQL_CONNECT_STR=postgresql://${DATA_E2E_ML_TRAINING_DB_USERNAME}:${DATA_E2E_ML_TRAINING_DB_PASSWORD}@${DATA_E2E_ML_TRAINING_DB_HOST}:${DATA_E2E_ML_TRAINING_DB_PORT}/${DATA_E2E_ML_TRAINING_DB_DATABASE}?sslmode=require
psql ${PSQL_CONNECT_STR} -f demo-ml/resources/sql/load_credit_card_dataset.sql
exit
```

2. Generate a resampled version of the imported data above:
```
pip install -U demo-ml/jobs/requirements.txt
python demo-ml/jobs/resample_dataset.py
```

3. The script above will generate a CSV file with the resampled data (_credit_card_resampled.csv_). 
Upload the file to your HuggingFace space (see <a href="https://huggingface.co/docs/datasets/share#upload-your-files" target="_blank">link</a>)

4. Create a custom MLModel which uses Gemfire data as its feature store:
```
MLFLOW_TRACKING_URI=${MLFLOW_TRACKING_URI} python demo-ml/resources/random_forest_madlib.py
```

5. To login to Argo, copy the token from here:
```
kubectl -n argo exec $(kubectl get pod -n argo -l 'app=argo-server' -o jsonpath='{.items[0].metadata.name}') -- argo auth token
```

6. Set up kubeseal (one-time op) :
```
https://github.com/bitnami-labs/sealed-secrets
```

7. Set up ML pipeline secrets (TODO: Use ExternalSecrets instead):
```
source .env
export GP_DATABASE_PW=<greenplum master password>
export PG_DATABASE_PW=<postgres inference password>
kubectl create secret generic greenplum-training-secret --from-literal=greenplum_master_password=${GP_DATABASE_PW} --dry-run=client -o yaml > training-db-secret.yaml
kubeseal --scope cluster-wide -o yaml <training-db-secret.yaml> demo-ml/argo/training-db-sealedsecret.yaml
kubectl create secret generic postgres-inference-secret --from-literal=postgres_password=${PG_DATABASE_PW} --dry-run=client -o yaml > inference-db-secret.yaml
kubeseal --scope cluster-wide -o yaml <inference-db-secret.yaml> demo-ml/argo/inference-db-sealedsecret.yaml
kubectl apply -f demo-ml/argo/training-db-sealedsecret.yaml -nargo
kubectl apply -f demo-ml/argo/inference-db-sealedsecret.yaml -nargo
```

8. Deploy ML pipelines:
```
ytt -f demo-ml/argo/install-argo-events-eventbus.yaml | kubectl apply -nargo -f -
ytt -f demo-ml/argo/argo-rabbitmq-eventsource.yaml -f demo-ml/argo/values.yaml  | kubectl apply -nargo -f -
ytt -f demo-ml/argo/argo-rabbitmq-ml-inference-trigger.yaml -f demo-ml/argo/values.yaml  | kubectl apply -nargo -f -
ytt -f demo-ml/argo/ml-training-pipeline.yaml -f demo-ml/argo/values.yaml | kubectl apply -nargo -f -
```

9. View progress:
```
watch kubectl get pods -nargo
```

* To delete the pipelines:
```
ytt -f demo-ml/argo/ml-training-pipeline.yaml -f demo-ml/argo/values.yaml | kubectl delete -nargo -f -
ytt -f demo-ml/argo/argo-rabbitmq-eventsource.yaml -f demo-ml/argo/values.yaml  | kubectl delete -nargo -f -
ytt -f demo-ml/argo/argo-rabbitmq-ml-inference-trigger.yaml -f demo-ml/argo/values.yaml  | kubectl delete -nargo -f -
ytt -f demo-ml/argo/install-argo-events-eventbus.yaml | kubectl delete -nargo -f -
```

## Alternative: Installing on local workstation <a name=workstation>
Instructions are provided in the main branch: [link](https://gitlab.eng.vmware.com/oawofolu/vmware-explore-demo-app)