# -*- mode: ruby -*-
# vi: set ft=ruby :

worker_count = (ENV["K8S_WORKER_COUNT"] || 1).to_i
public_network_enabled = (ENV["K8S_PUBLIC_NETWORK_ENABLED"] || '0') == '1'
public_network_bridge = ENV["K8S_PUBLIC_NETWORK_BRIDGE"]

private_ip_master = "192.168.33.10"

def ip_plus_i(ip, i)
  splits = ip.split('.')
  splits[3] = (splits[3].to_i + i).to_s
  return splits.join('.')
end

cluster = [{
  :name => "k8s-master",
  :ip => private_ip_master,
  :cpus => 4,
  :memory => 4096
}]

(1..worker_count).each do |i|
  cluster << {
    :name => "k8s-worker-#{i}",
    :ip => ip_plus_i(private_ip_master, i),
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
        if public_network_bridge.nil?
          node_config.vm.network "public_network"
        else
          node_config.vm.network "public_network", bridge: public_network_bridge
        end
      else
        node_config.vm.network "private_network", ip: node[:ip]
      end

      node_config.vm.provider "virtualbox" do |vb|
        vb.name = node[:name]
        vb.cpus = node[:cpus]
        vb.memory = node[:memory]
      end

      if node[:name] == "k8s-master"
        node_config.vm.provision "shell", path: "./master.sh"
      else
        node_config.vm.provision "shell", path: "./worker.sh"
      end
    end
  end

  config.vm.provision "shell", path: "./common.sh"
end
