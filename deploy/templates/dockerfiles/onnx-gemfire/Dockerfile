FROM nginx:1.19.10-alpine
RUN mkdir -p /usr/share/nginx/other; \
    mkdir -p /usr/share/nginx/yaml;
COPY *.jar /usr/share/nginx/other
COPY *.yaml /usr/share/nginx/yaml