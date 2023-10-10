sed -i "s/XYZCHANGESETID/$(date +%s)/g; s/XYZDBSCHEMA/${DB_SCHEMA}/g;" ${SHARED_PATH}/${DB_SCRIPT}/tmp/${DB_SCRIPT} > /tmp/${DB_SCRIPT}
cat /tmp/${DB_SCRIPT} > ${SHARED_PATH}/${DB_SCRIPT}