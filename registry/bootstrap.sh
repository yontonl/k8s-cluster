#!/usr/bin/env bash

if [ "$(command -v docker)" ]; then
    BUILDER="docker"
elif [ "$(command -v podman)" ]; then
    BUILDER="podman"
else
    echo "Only support docker or podman"
    exit 1
fi

REGISTRY_DOMAIN="registry.k8s.local"
sudo tee -a /etc/hosts <<EOF
127.0.0.1 ${REGISTRY_DOMAIN}
EOF

openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
  -keyout "$(pwd)/certs/${REGISTRY_DOMAIN}/${REGISTRY_DOMAIN}.key" \
  -out "$(pwd)/certs/${REGISTRY_DOMAIN}/${REGISTRY_DOMAIN}.crt" \
  -subj "/CN=${REGISTRY_DOMAIN}" \
  -addext "subjectAltName = DNS:${REGISTRY_DOMAIN}"

$BUILDER run -d \
  --restart=always \
  --name registry \
  -v "$(pwd)"/certs/${REGISTRY_DOMAIN}:/certs \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/${REGISTRY_DOMAIN}.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/${REGISTRY_DOMAIN}.key \
  -e REGISTRY_STORAGE_DELETE_ENABLED=true \
  -p 443:443 \
  registry:2