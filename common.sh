#!/usr/bin/env bash

echo "Provisioning common.sh ..."

################################################################################
# Step 1: environment settings
cat >> /etc/hosts <<EOF
192.168.10.242 registry.k8s.local
192.168.10.160 master.k8s.local
192.168.10.161 worker-1.k8s.local
192.168.10.162 worker-2.k8s.local
192.168.10.163 worker-3.k8s.local
192.168.10.164 worker-4.k8s.local
192.168.10.165 worker-5.k8s.local
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