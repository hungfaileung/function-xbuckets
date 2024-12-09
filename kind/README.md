./delete-kind-and-registry.sh

./create-kind-and-registry.sh

./install-crossplane.sh

cd ..

sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain kind/certs/registry.crt

docker build . --quiet --platform=linux/amd64 --tag runtime-amd64
docker build . --quiet --platform=linux/arm64 --tag runtime-arm64

crossplane xpkg build \
    --package-root=package \
    --embed-runtime-image=runtime-amd64 \
    --package-file=function-amd64.xpkg
crossplane xpkg build \
    --package-root=package \
    --embed-runtime-image=runtime-arm64 \
    --package-file=function-arm64.xpkg

crossplane xpkg push --package-files=function-amd64.xpkg,function-arm64.xpkg localhost:5000/function-xbuckets:v0.1.0

curl https://localhost:5000/v2/_catalog
curl https://localhost:5000/v2/function-xbuckets/tags/list

kubectl apply -f example/functions.yaml
kubectl apply -f example/xrd.yaml
kubectl apply -f example/composition.yaml
kubectl apply -f example/xr.yaml

kubectl apply -f example/provider.yaml

# login aws

sed -e 's/xxx:xxx' -e 's/; Managed by xxx//' ~/.aws/credentials > ./aws_credentials.txt
kubectl create secret generic aws-secret -n crossplane-system --from-file=creds=./aws_credentials.txt
rm ./aws_credentials.txt

cat <<EOF | kubectl apply -f -
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-secret
      key: creds
EOF

kubectl describe xbuckets
kubectl get managed
crossplane beta trace xbuckets