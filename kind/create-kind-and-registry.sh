#!/bin/sh
set -o errexit

KIND_CLUSTER_NAME=kind
REGISTRY_NAME=kind-registry

# kind cluster
cat <<EOF | kind create cluster --name $KIND_CLUSTER_NAME --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".$REGISTRY_NAME]
    config_path = "/etc/containerd/certs.d"
EOF

kubectl cluster-info --context kind-$KIND_CLUSTER_NAME

REGISTRY_DIR="/etc/containerd/certs.d/$REGISTRY_NAME:5000"
for node in $(kind get nodes); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."https://${REGISTRY_NAME}:5000"]
EOF
done

# self-signed local registry
mkdir -p certs

CERT_CONFIG_FILE=certs/openssl.cnf
cat <<EOF > $CERT_CONFIG_FILE
[req]
[req]
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Organization
CN = $REGISTRY_NAME

[req_ext]
subjectAltName = @alt_names

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $REGISTRY_NAME
DNS.2 = localhost
EOF

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/registry.key \
  -out certs/registry.crt \
  -config $CERT_CONFIG_FILE

cat certs/registry.crt certs/registry.key > certs/ca-bundle.pem

docker run \
    -d --restart=always -p 5000:5000 --network bridge --name "${REGISTRY_NAME}" \
    -v $(pwd)/certs:/certs \
    -e REGISTRY_HTTP_ADDR=0.0.0.0:5000 \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry.crt \
    -e REGISTRY_HTTP_TLS_KEY=/certs/registry.key \
    registry:2

if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${REGISTRY_NAME}")" = 'null' ]; then
  docker network connect "kind" "${REGISTRY_NAME}"
fi

# add self-signed certificate to the kind cluster
docker cp certs/registry.crt kind-control-plane:/usr/local/share/ca-certificates/registry.crt
docker exec -it kind-control-plane update-ca-certificates
docker exec -it kind-control-plane systemctl restart containerd

docker ps
