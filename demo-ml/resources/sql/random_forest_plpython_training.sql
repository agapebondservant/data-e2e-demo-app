--liquibase formatted sql
--changeset gpadmin:XYZCHANGESETID
CREATE OR REPLACE FUNCTION XYZDBSCHEMA.run_training_task (entry_point text,
                                        experiment_name text,
                                        mlflow_host text,
                                        mlflow_s3_uri text,
                                        app_location text)
RETURNS TEXT
AS $$
    # container: plc_python3_shared
    import os
    import sys
    import subprocess
    import logging
    logging.getLogger().addHandler(logging.StreamHandler())
    logging.getLogger().addHandler(logging.FileHandler(f"{app_location}/debug.log"))
    import importlib
    import pkgutil
    try:
        os.environ['MLFLOW_TRACKING_URI']=mlflow_host
        os.environ['MLFLOW_S3_ENDPOINT_URL']=mlflow_s3_uri
	    os.environ['mlflow_entry']=entry_point
        os.environ['experiment_name']=experiment_name
        os.environ['shared_app_path']=app_location
        sys.path.append(f'{app_location}/_vendor')

	    # inject python code here

        return subprocess.check_output('ls -ltr /', shell=True).decode(sys.stdout.encoding).strip()
    except subprocess.CalledProcessError as e:
        plpy.error(e.output)
$$
LANGUAGE 'plpython3u';