from mlflow import MlflowClient

client = MlflowClient()
for rm in client.search_registered_models():
    try:
        client.delete_registered_model(rm.name)
        print(f"Model {rm.name} deleted.")
    except Exception:
        continue
