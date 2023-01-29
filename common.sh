#!/usr/bin/env bash

echo "Provisioning common.sh..."

################################################################################
# Step 1: environment settings
cat >> /etc/hosts <<EOF
$(ifconfig eth1 | grep 'inet ' | awk -F' ' '{ print $2 }') $(hostname)
EOF

timedatectl set-timezone Asia/Shanghai
cat > /etc/environment <<EOF
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
EOF

sed -i.bak 's/plugins=1/plugins=0/g' /etc/yum.conf
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
         -e 's|^#baseurl=http://mirror.centos.org/centos|baseurl=https://mirrors.ustc.edu.cn/centos|g' \
         -i.bak \
         /etc/yum.repos.d/CentOS-Base.repo
yum makecache
yum install -y vim wget curl net-tools bind-utils bash-completion ipvsadm

################################################################################
# Step 2: kernel modules and settings
modules='overlay br_netfilter ip_vs ip_vs_rr ip_vs_wrr ip_vs_sh nf_conntrack_ipv4'
for module in ${modules}; do
    if ! lsmod | grep -q "${module}"; then
        modprobe "${module}"
        echo "${module}" | tee -a /etc/modules-load.d/k8s.conf
    fi
done

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
fs.may_detach_mounts = 1
vm.swappiness = 0
EOF

sysctl --system

################################################################################
# Step 3: disable swap, firewalld and selinux
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

systemctl stop firewalld
systemctl disable firewalld

setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

################################################################################
# Step 4: install containerd
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/docker-ce.repo
sed -i 's#download.docker.com#mirrors.tuna.tsinghua.edu.cn/docker-ce#g' /etc/yum.repos.d/docker-ce.repo

yum install -y containerd.io

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's#k8s.gcr.io#registry.aliyuncs.com/google_containers#g' /etc/containerd/config.toml
sed -i 's#registry.k8s.io#registry.aliyuncs.com/google_containers#g' /etc/containerd/config.toml
sed -i 's#SystemdCgroup = false#SystemdCgroup = true#g' /etc/containerd/config.toml
sed -i 's#config_path = ""#config_path = "/etc/containerd/certs.d"#g' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

################################################################################
# Step 5: install kubeadm, kubelet and kubectl
KUBE_VERSION=1.22.17

cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.tuna.tsinghua.edu.cn/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
EOF

yum install -y kubelet-$KUBE_VERSION kubeadm-$KUBE_VERSION kubectl-$KUBE_VERSION --disableexcludes=kubernetes
systemctl enable kubelet

cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

################################################################################
# Step 6: add private container registry certs
ln -sf /vagrant/registry/certs /etc/containerd/certs.d

################################################################################
# Step 7: install nfs
yum install -y nfs-utils