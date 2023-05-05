#!/bin/bash

echo "Deploying Rabbit cluster..."

export DEMO_RABBIT_NS=$1

ytt -f deploy/templates/demo-data/rabbitmq-cluster.yaml \
    -f deploy/templates/demo-data/rabbitmq-objects.yaml \
    -f deploy/templates/demo-data/values.yaml | kubectl apply -n $DEMO_RABBIT_NS -f -

echo "Rabbit cluster deployed."