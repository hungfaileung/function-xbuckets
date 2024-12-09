#!/bin/sh
set -o errexit

KIND_CLUSTER_NAME=kind
REGISTRY_NAME=kind-registry

kind delete cluster --name $KIND_CLUSTER_NAME

docker rm -f $REGISTRY_NAME
