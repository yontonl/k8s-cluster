#!/usr/bin/env bash

echo "Provisioning worker.sh ..."

curl –sfL https://rancher-mirror.oss-cn-beijing.aliyuncs.com/k3s/k3s-install.sh | \
    INSTALL_K3S_MIRROR=cn \
    K3S_URL=https://master.k8s.local:6443 \
    K3S_TOKEN=$(cat /vagrant/node-token) \
    sh -