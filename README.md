# VMWARE DATA DEMO APP

## Credits
<div class="alert alert-primary" role="alert">
This was forked from the <b>Anomaly Detection demo</b> presented at <a href="https://vmware-explore-in.cventevents.com/event/1afa043a-2293-433d-9d63-85ff52ba8584/websitePage:f980d165-31f2-4d39-af64-2dfc5826a836" target="_blank">VMExplore India 2023</a>,
and leverages the source code from their hard work.<br/>
To learn more, please see the original git repository at <a href="https://gitlab.eng.vmware.com/oawofolu/vmware-explore-demo-app" target="_blank">here</a>.
</div>

## Installing on Kubernetes
1. Make sure you set up the following pre-requisites:
- [ ] Kubernetes 1.23+
- [ ] Maven (supported version)
- [ ] Project Contour
- [ ] Environment file (.env)
* Must create .env file (should be located at project root)
* Use .env-sample as a guide
- [ ] Values.yaml files
* Must create deploy/templates/demo-ui/values.yaml and deploy/templates/demo-data/values.yaml
* Use values-template.yaml as a guide

2. Prepare manifest files:
```
source .env
for orig in `find . -name "*.in.*" -type f`; do
  target=$(echo $orig | sed 's/\.in//')
  envsubst < $orig > $target
  grep -qxF $target .gitignore || echo $target >> .gitignore
done
```

## Contents
1. [Set up Gemfire and RabbitMQ](#gemfire-and-rabbit)
2. [Set up frontend and backend apps](#frontend-backend-apps)
3. [Alternative: Installing on Workstation](#workstation)

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

6. Create Gemfire region:
```
kubectl exec -it gfanomaly-server-0 -n $DEMO_NS -- gfsh -e "connect --locator=gfanomaly-locator-0.gfanomaly-locator.anomaly-ns.svc.cluster.local[10334]" -e "create region --name=mds-region --type=REPLICATE --enable-statistics --entry-idle-time-expiration=300"
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
  * For Gemfire Pulse endpoint: gfanomaly-locator.<YOUR-FQDN-DOMAIN>/pulse (default credentials: admin/admin)
  * For Gemfire REST API: gfanomaly-server.<YOUR-FQDN-DOMAIN>/gemfire-api/v1
  * For RabbitMQ Management endpoint: rmqanomaly.<YOUR-FQDN-DOMAIN>
  * Get login credentials for RabbitMQ Management console:
```
kubectl get secret rmqanomaly-default-user -o jsonpath="{.data.default_user\.conf}" -n $DEMO_NS | base64 --decode
```

* To delete the Gemfire and RabbitMQ clusters:
```
kubectl delete all --all -n $DEMO_NS
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
  * For UI: demo-ui.<YOUR-FQDN-DOMAIN>

  * To delete the frontend and backend apps:
```
ytt -f deploy/templates/demo-ui/ | kubectl delete -f -
kubectl delete -f deploy/templates/demo-app/
kubectl delete ns vmware-explore
```

## Alternative: Installing on local workstation <a name=workstation>
Instructions are provided in the main branch: [link](https://gitlab.eng.vmware.com/oawofolu/vmware-explore-demo-app)