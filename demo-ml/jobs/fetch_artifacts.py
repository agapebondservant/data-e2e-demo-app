import mlflow
from mlflow import MlflowClient
from dotenv import load_dotenv
import os

load_dotenv()

client = MlflowClient()

prior_runs = mlflow.search_runs(
    filter_string=f"tags.latest = 'true'",
    output_format='list')
for prior_run in prior_runs:
    artifacts = client.list_artifacts(prior_run.info.run_id)
    for artifact in artifacts:
        client.artifacts.download_artifacts(run_id=prior_run.info.run_id, dst_path=os.getenv('ARTIFACT_DESTINATION'))
