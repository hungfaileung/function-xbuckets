#!/bin/sh
set -o errexit

KIND_CLUSTER_NAME=kind
REGISTRY_NAME=kind-registry
CROSSPLANE_NAMESPACE=crossplane-system
CA_BUNDLE_CONTENT=$(cat certs/ca-bundle.pem)
CONFIGMAP_NAME=registry-ca-bundle

kubectl create namespace $CROSSPLANE_NAMESPACE

cat <<EOF | kubectl apply -n $CROSSPLANE_NAMESPACE -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: $CONFIGMAP_NAME
data:
  ca-bundle.pem: |
$(echo "$CA_BUNDLE_CONTENT" | sed -e 's/^/    /')
EOF


helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane \
  --namespace $CROSSPLANE_NAMESPACE \
  --set registryCaBundleConfig.key=ca-bundle.pem \
  --set registryCaBundleConfig.name=registry-ca-bundle \
  crossplane-stable/crossplane

kubens $CROSSPLANE_NAMESPACE
