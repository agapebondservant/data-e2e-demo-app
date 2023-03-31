FROM bitnami/node:16 AS builder
WORKDIR /src/app
COPY package.json package-lock.json /src/app/
RUN npm config set registry  http://build-artifactory.eng.vmware.com/artifactory/api/npm/npm
RUN npm ci
COPY . .
RUN ls -lrt .
RUN npm run build:prod

FROM bitnami/nginx:latest
COPY --from=builder /src/app/dist/demo-ui/  /opt/bitnami/nginx/html
ARG COMMIT_ID
ENV COMMIT_ID=${COMMIT_ID}
COPY nginx.conf /opt/bitnami/nginx/conf/
COPY conf.d /opt/bitnami/nginx/conf/conf.d/
RUN ls -lrt /opt/bitnami/nginx/conf/
USER root
RUN mkdir -p /opt/bitnami/nginx/log/nginx/
RUN chmod -R 777 /opt/bitnami/
RUN chmod -R 777 /opt/bitnami/nginx/log/nginx/
USER 1001
EXPOSE 8080
