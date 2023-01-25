#!/usr/bin/env bash

if [ "$(command -v docker)" ]; then
    BUILDER="docker"
elif [ "$(command -v podman)" ]; then
    BUILDER="podman"
else
    echo "Only support docker or podman"
    exit 1
fi

K8S_REGISTRY_HOST="registry.k8s.local"
sudo tee -a /etc/hosts <<EOF
127.0.0.1 ${K8S_REGISTRY_HOST}
EOF

if [ ! -d "$(pwd)/certs/${K8S_REGISTRY_HOST}" ]; then
  mkdir -p "$(pwd)/certs/${K8S_REGISTRY_HOST}"
  openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
    -keyout "$(pwd)/certs/${K8S_REGISTRY_HOST}/${K8S_REGISTRY_HOST}.key" \
    -out "$(pwd)/certs/${K8S_REGISTRY_HOST}/${K8S_REGISTRY_HOST}.crt" \
    -subj "/CN=${K8S_REGISTRY_HOST}" \
    -addext "subjectAltName = DNS:${K8S_REGISTRY_HOST}"
fi

$BUILDER run -d \
  --restart=always \
  --name registry \
  -v "$(pwd)"/certs/${K8S_REGISTRY_HOST}:/certs \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/${K8S_REGISTRY_HOST}.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/${K8S_REGISTRY_HOST}.key \
  -e REGISTRY_STORAGE_DELETE_ENABLED=true \
  -p 443:443 \
  registry:2