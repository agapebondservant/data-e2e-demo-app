FROM python:3.10-slim

ENV PYTHONUNBUFFERED=1
ENV PYTHONIOENCODING=UTF-8

RUN apt-get update && \
    apt-get install -y git python3-dotenv gettext-base && \
    pip3 install mlflow==2.7.0 python-dotenv

ENTRYPOINT ["sh"]