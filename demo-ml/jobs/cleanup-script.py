import mlflow
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
Clean up default model runs
"""
print("Cleaning up default experiment...")
runs = mlflow.search_runs(output_format='list')
for run in runs:
    mlflow.delete_run(run.info.run_id)
    print(f"MLflow Run ID {run.info.run_id} deleted.")

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
Clean up training database
"""
print("Cleaning up training database...")
subprocess.run(
    f'psql {os.path.expandvars("${PSQL_CONNECT_STR}")} -c "UPDATE DATABASECHANGELOGLOCK SET LOCKED=0::boolean, LOCKGRANTED=null, LOCKEDBY=null where ID=1;"; ' +
    f'psql {os.path.expandvars("${PSQL_CONNECT_STR}")} -c "TRUNCATE TABLE rf_model_versions ; TRUNCATE TABLE rf_credit_card_transactions_model_evaluations;"; ' +
    f'psql {os.path.expandvars("${PSQL_CONNECT_STR}")} -c "DO \\$\\$ DECLARE s text; BEGIN FOR s IN SELECT nspname FROM pg_namespace WHERE nspname LIKE \'m1%\' LOOP EXECUTE \'DROP SCHEMA \' || quote_ident(s) || \' CASCADE\'; END LOOP; END;\\$\\$;"; ' +
    f'psql {os.path.expandvars("${PSQL_CONNECT_STR}")} -c "VACUUM FULL"; ',
    shell=True
)
print("Database cleanup complete.")
