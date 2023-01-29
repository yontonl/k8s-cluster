#!/usr/bin/env bash

echo "Provisioning master.sh..."

USER=vagrant
K8S_MASTER_ADDR=$1

################################################################################
# Step 1: kubeadm init
kubeadm config images pull --image-repository=registry.aliyuncs.com/google_containers
kubeadm init \
    --apiserver-advertise-address="${K8S_MASTER_ADDR}" \
    --apiserver-cert-extra-sans="${K8S_MASTER_ADDR}" \
    --image-repository=registry.aliyuncs.com/google_containers \
    --pod-network-cidr=10.244.0.0/16 \

mkdir -p /home/${USER}/.kube
cp /etc/kubernetes/admin.conf /home/${USER}/.kube/config
chown ${USER}:${USER} /home/${USER}/.kube/config

kubeadm token create --print-join-command > /vagrant/join.sh

################################################################################
# Step 2: install flannel
KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f /vagrant/kube-flannel.yml

################################################################################
# Step 3: install dashboard
KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f /vagrant/dashboard.yml

################################################################################
# Step 4: install Helm
HELM_VERSION=v3.11.0
wget https://repo.huaweicloud.com/helm/${HELM_VERSION}/helm-${HELM_VERSION}-linux-amd64.tar.gz
tar -zxvf helm-${HELM_VERSION}-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
rm -rf helm-${HELM_VERSION}-linux-amd64.tar.gz linux-amd64

################################################################################
# Step 5: provision nfs
mkdir -p /data/nfs
echo "/data/nfs *(insecure,rw,sync,no_root_squash,no_subtree_check)" > /etc/exports
systemctl enable --now rpcbind
systemctl enable --now nfs-server

################################################################################
# Step 6: provision default storage class
KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f /vagrant/sc.yml

################################################################################
# Step 7: provision metrics-server
KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f /vagrant/metrics-server.yml