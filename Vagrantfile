# Variables
BOX_NAME = "ubuntu/focal64"

# Load balancer IPs
MASTER_LB_IP = "192.168.56.10"
WORKER_LB_IP = "192.168.56.11"

# VM details
MASTER_NODES = [ "192.168.56.12", "192.168.56.13", "192.168.56.14" ]
WORKER_NODES = [ "192.168.56.15", "192.168.56.16", "192.168.56.17" ]
#MASTER_NODES = [ "192.168.56.12" ]
#WORKER_NODES = [ "192.168.56.15" ]
NETMASK = "255.255.255.0"

Vagrant.configure("2") do |config|
  
  # Add hosts file entries for all nodes
  config.vm.provision "shell", inline: <<-SHELL
    echo "192.168.56.10  lb-master" >> /etc/hosts
    echo "192.168.56.11  lb-worker" >> /etc/hosts
    echo "192.168.56.12  master-1" >> /etc/hosts
    echo "192.168.56.13  master-2" >> /etc/hosts
    echo "192.168.56.14  master-3" >> /etc/hosts
    echo "192.168.56.15  worker-1" >> /etc/hosts
    echo "192.168.56.16  worker-2" >> /etc/hosts
    echo "192.168.56.17  worker-3" >> /etc/hosts
  SHELL

  # Load balancer - Control Plane
  config.vm.define "lb-master" do |lbmaster|
    lbmaster.vm.box = BOX_NAME
    lbmaster.vm.hostname = "lb-master"
    lbmaster.vm.network "private_network", ip: MASTER_LB_IP, netmask: NETMASK
    lbmaster.vm.provider "virtualbox" do |vb|
      vb.name = "lb-master"
      vb.memory = 1024
      vb.cpus = 1
    end
    lbmaster.vm.provision "shell", inline: <<-SHELL
      apt-get -y install haproxy
      cp /vagrant/haproxy_config/haproxy.cfg.master /etc/haproxy/haproxy.cfg
      service haproxy restart
    SHELL
  end

  # Load balancer - Workers
  config.vm.define "lb-worker" do |lbworker|
    lbworker.vm.box = BOX_NAME
    lbworker.vm.hostname = "lb-worker"
    lbworker.vm.network "private_network", ip: WORKER_LB_IP, netmask: NETMASK
    lbworker.vm.provider "virtualbox" do |vb|
      vb.name = "lb-worker"
      vb.memory = 1024
      vb.cpus = 1
    end
    lbworker.vm.provision "shell", inline: <<-SHELL
      apt-get -y install haproxy
      cp /vagrant/haproxy_config/haproxy.cfg.worker /etc/haproxy/haproxy.cfg
      service haproxy restart
    SHELL
  end

  # Master nodes
  MASTER_NODES.to_enum.with_index(1).each do |ip, i|
    config.vm.define "master-#{i}" do |master|
      master.vm.box = BOX_NAME
      master.vm.hostname = "master-#{i}"
      master.vm.network "private_network", ip: "#{ip}", netmask: NETMASK
      master.vm.provider "virtualbox" do |vb|
        vb.name = "master-#{i}"
        vb.memory = 2048
        vb.cpus = 2
      end
      master.vm.provision "shell", path: "scripts/common.sh"
      if i == 1
        master.vm.provision "shell", path: "scripts/master.sh", args: [MASTER_LB_IP]
      else
        master.vm.provision "shell", path: "config/join_master.sh", args: ["#{ip}", "master-#{i}"]
      end
    end
  end

  # Worker nodes
  WORKER_NODES.to_enum.with_index(1).each do |ip, i|
    config.vm.define "worker-#{i}" do |node|
      node.vm.box = BOX_NAME
      node.vm.hostname = "worker-#{i}"
      node.vm.network "private_network", ip: "#{ip}", netmask: NETMASK
      node.vm.provider "virtualbox" do |vb|
        vb.name = "worker-#{i}"
        vb.memory = 1024
        vb.cpus = 1
      end
      node.vm.provision "shell", path: "scripts/common.sh"
      node.vm.provision "shell", inline: "sudo /bin/bash /vagrant/config/join_worker.sh -v"
    end
  end

end
