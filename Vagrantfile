

# -*- mode: ruby -*-
# vi: set ft=ruby :

worker_count = (ENV["K8S_WORKER_COUNT"] || 3).to_i
master_addr = ENV["K8S_MASTER_ADDR"] || "192.168.136.160"
registry_addr = ENV["K8S_REGISTRY_ADDR"]
registry_port = ENV["K8S_REGISTRY_PORT"]
registry_host = ENV["K8S_REGISTRY_HOST"]

def ip_plus_i(ip, i)
  splits = ip.split('.')
  splits[3] = (splits[3].to_i + i).to_s
  return splits.join('.')
end

cluster = [{
  :name => "master.k8s.local",
  :ip => master_addr,
  :cpus => 4,
  :memory => 4096
}]

hosts = []
if registry_addr && registry_port && registry_host
  hosts << "#{registry_addr} #{registry_host}"
end

hosts << "#{master_addr} master.k8s.local"
(1..worker_count).each do |i|
  hosts << "#{ip_plus_i(master_addr, i)} worker-#{i}.k8s.local"
  cluster << {
    :name => "worker-#{i}.k8s.local",
    :ip => ip_plus_i(master_addr, i),
    :cpus => 2,
    :memory => 2048
  }
end

hosts = hosts.join("\n")

Vagrant.configure("2") do |config|
  cluster.each do |node|
    config.vm.define node[:name] do |node_config|
      node_config.vm.box = "bento/centos-7"
      node_config.vm.hostname = node[:name]
      node_config.vm.network "private_network", ip: node[:ip]

      node_config.vm.provider "virtualbox" do |vb|
        vb.name = node[:name]
        vb.cpus = node[:cpus]
        vb.memory = node[:memory]
      end

      node_config.vm.provider "parallels" do |pvl|
        pvl.name = node[:name]
        pvl.cpus = node[:cpus]
        pvl.memory = node[:memory]
      end

      if node[:name] == "master.k8s.local"
        node_config.vm.provision "shell", path: "./master.sh", args: ["#{master_addr}"]
      else
        node_config.vm.provision "shell", path: "./worker.sh"
      end
    end
  end

  config.vm.provision "shell", inline: "echo '#{hosts}' >> /etc/hosts"
  config.vm.provision "shell", path: "./common.sh"
end