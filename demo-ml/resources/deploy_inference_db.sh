chmod +w ${SHARED_PATH}/${DB_SCRIPT}
sed -i "" "s/XYZCHANGESETID/$(date +%s)/g; s/XYZDBSCHEMA/${DB_SCHEMA}/g;" ${SHARED_PATH}/${DB_SCRIPT}