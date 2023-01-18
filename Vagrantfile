# -*- mode: ruby -*-
# vi: set ft=ruby :

worker_count = (ENV["K8S_WORKER_COUNT"] || 3).to_i
public_network_enabled = (ENV["K8S_PUBLIC_NETWORK_ENABLED"] || '0') == '1'
registry_hosts = ENV["K8S_REGISTRY_HOSTS"]

ip_master = "192.168.10.160"

def ip_plus_i(ip, i)
  splits = ip.split('.')
  splits[3] = (splits[3].to_i + i).to_s
  return splits.join('.')
end

cluster = [{
  :name => "master.k8s.local",
  :ip => ip_master,
  :cpus => 4,
  :memory => 4096
}]

(1..worker_count).each do |i|
  cluster << {
    :name => "worker-#{i}.k8s.local",
    :ip => ip_plus_i(ip_master, i),
    :cpus => 2,
    :memory => 2048
  }
end

Vagrant.configure("2") do |config|
  cluster.each do |node|
    config.vm.define node[:name] do |node_config|
      node_config.vm.box = "bento/centos-7"
      node_config.vm.hostname = node[:name]
      
      if public_network_enabled
        node_config.vm.network "public_network", ip: node[:ip], bridge: "en1: Wi-Fi (en1) (AirPort)"
      else
        node_config.vm.network "private_network", ip: node[:ip]
      end

      node_config.vm.provider "virtualbox" do |vb|
        vb.name = node[:name]
        vb.cpus = node[:cpus]
        vb.memory = node[:memory]
      end

      node_config.vm.provision "shell", inline: <<-SHELL
      rm -f /etc/hosts
      ln -sf /vagrant/hosts /etc/hosts
      if [ $(hostname) == "master.k8s.local" ]; then
        echo "#{registry_hosts}" >> /etc/hosts
      fi
      SHELL

      if node[:name] == "master.k8s.local"
        node_config.vm.provision "shell", path: "./master.sh"
      else
        node_config.vm.provision "shell", path: "./worker.sh"
      end
    end
  end

  config.vm.provision "shell", path: "./common.sh"
end
