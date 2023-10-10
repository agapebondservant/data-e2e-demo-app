from mlflow import MlflowClient
import subprocess
import os

"""
Clean up model registry
"""
print("Cleaning up model registry...")
client = MlflowClient()
for rm in client.search_registered_models():
    try:
        client.delete_registered_model(rm.name)
        print(f"Model {rm.name} deleted.")
    except Exception:
        continue
print("Model registry cleanup complete.")

"""
Clean up pipelines
"""
print("Cleaning up ML pipelines...")
subprocess.run(
    'ytt -f demo-ml/argo/ml-training-pipeline.yaml -f demo-ml/argo/values.yaml | kubectl delete -nargo -f - ;' +
    'ytt -f demo-ml/argo/argo-rabbitmq-eventsource.yaml -f demo-ml/argo/values.yaml  | kubectl delete -nargo -f - ;' +
    'ytt -f demo-ml/argo/argo-rabbitmq-ml-inference-trigger.yaml -f demo-ml/argo/values.yaml  | kubectl delete -nargo -f - ;' +
    'ytt -f demo-ml/argo/install-argo-events-eventbus.yaml | kubectl delete -nargo -f - ;', shell=True)
print("ML pipelines cleanup complete.")

"""
Clean up database
"""
print("Cleaning up database...")
subprocess.run(
    f'psql {os.path.expandvars("${PSQL_CONNECT_STR}")} -c "UPDATE DATABASECHANGELOGLOCK SET LOCKED=0::boolean, LOCKGRANTED=null, LOCKEDBY=null where ID=1;"; ' +
    f'psql {os.path.expandvars("${PSQL_CONNECT_STR}")} -c "TRUNCATE TABLE rf_model_versions ; TRUNCATE TABLE rf_credit_card_transactions_model_evaluations;"; ' +
    f'psql {os.path.expandvars("${PSQL_CONNECT_STR}")} -c "DO \\$\\$ DECLARE s text; BEGIN FOR s IN SELECT nspname FROM pg_namespace WHERE nspname LIKE \'m1\\_%\' LOOP EXECUTE \'DROP SCHEMA "\' || quote_ident(s) || \'" CASCADE\'; END LOOP; END;\\$\\$;"; ',
    shell=True
)
print("Database cleanup complete.")
