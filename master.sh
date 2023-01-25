#!/usr/bin/env bash

echo "Provisioning master.sh ..."

USER=vagrant

curl –sfL https://rancher-mirror.oss-cn-beijing.aliyuncs.com/k3s/k3s-install.sh | \
    INSTALL_K3S_MIRROR=cn sh -s - \
    --system-default-registry "registry.cn-hangzhou.aliyuncs.com" \
    --write-kubeconfig /home/${USER}/.kube/config \
    --write-kubeconfig-mode 666

sudo cp /var/lib/rancher/k3s/server/node-token /vagrant