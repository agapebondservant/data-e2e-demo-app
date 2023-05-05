FROM harbor-repo.vmware.com/dockerhub-proxy-cache/library/photon:4.0
RUN yum install -y wget
RUN yum install -y rpm
RUN wget http://build-squid.eng.vmware.com/build/mts/release/bora-16899260/publish/lin64/rpm/vmware-jre-11.0.8-zre41.24.x86_64.rpm && rpm -U vmware-jre-11.0.8-zre41.24.x86_64.rpm
COPY target/demo-0.0.1-SNAPSHOT.jar demo-0.0.1-SNAPSHOT.jar
ENV JAVA_HOME=/usr/java/jre-vmware
ARG COMMIT_ID
ENV COMMIT_ID=${COMMIT_ID}
USER root
RUN chmod -R 666 $JAVA_HOME/lib/security/cacerts
USER 1001
ENTRYPOINT ["/usr/java/jre-vmware/bin/java","-jar","demo-0.0.1-SNAPSHOT.jar"]