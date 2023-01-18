#!/usr/bin/env bash

echo "Provisioning master.sh ..."

IP_ADDR=$(ifconfig eth1 | grep 'inet ' | awk -F' ' '{ print $2 }')
USER=vagrant

################################################################################
# Step 1: kubeadm init
kubeadm config images pull --image-repository=registry.aliyuncs.com/google_containers
kubeadm init \
    --apiserver-advertise-address="${IP_ADDR}" \
    --apiserver-cert-extra-sans="${IP_ADDR}" \
    --image-repository=registry.aliyuncs.com/google_containers \
    --pod-network-cidr=10.244.0.0/16 \

mkdir -p /home/${USER}/.kube
cp /etc/kubernetes/admin.conf /home/${USER}/.kube/config
chown ${USER}:${USER} /home/${USER}/.kube/config

kubeadm token create --print-join-command > /vagrant/join.sh

################################################################################
# Step 2: install flannel
KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f /vagrant/flannel.yml

################################################################################
# Step 3: install dashboard
KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f /vagrant/dashboard.yml
