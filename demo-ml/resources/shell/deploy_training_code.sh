ssh -i ${SCP_PEM_PATH} ${USER}@${HOST} -o "StrictHostKeyChecking=no" "sudo yum install csnappy-devel -y;
rm -rf ${SHARED_PATH}/mlfraudapp; \
curl -o vendor.tar.gz ${PYFUNC_VENDOR_URI}; \
mkdir -p ${SHARED_PATH}/mlfraudapp/_vendor; \
tar -xvzf vendor.tar.gz -C ${SHARED_PATH}/mlfraudapp/_vendor --strip-components=1;"