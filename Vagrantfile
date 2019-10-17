# -*- mode: ruby -*-
# vi: set ft=ruby :

BOX_IMAGE = "sbeliakou/centos"
NODE_COUNT = 1
SRV_NAME = "zbx-srv"
NODE_NAME = "zbx-ag"
#network variables
SUBNET = "192.168.56"
NET_START = 106
SRV_IP = "#{SUBNET}.#{NET_START}"
#mariadb variables
MARIADB_USER = "zabbix"
MARIADB_PASSWD = "12345"



Vagrant.configure("2") do |config|
  config.vm.define SRV_NAME do |subconfig|
    subconfig.vm.box = BOX_IMAGE
    subconfig.vm.hostname = SRV_NAME
    subconfig.vm.network "private_network", ip: "#{SUBNET}.#{NET_START}"
           subconfig.vm.provider "virtualbox" do |vb|
              vb.memory = "1024"
              vb.name = SRV_NAME
           end
  end
  
  (1..NODE_COUNT).each do |i|
    config.vm.define "#{NODE_NAME}#{i}" do |subconfig|
      subconfig.vm.box = BOX_IMAGE
      subconfig.vm.hostname = "#{NODE_NAME}#{i}"
      subconfig.vm.network "private_network", ip: "#{SUBNET}.#{i+NET_START}"
           subconfig.vm.provider "virtualbox" do |vb|
              vb.memory = "1024"
              vb.name = "#{NODE_NAME}#{i}"
           end
    end
  end
    config.vm.provision "shell", path: "script.sh", env: {"srv_name" => SRV_NAME, "srv_ip" => SRV_IP, "mariadb_user" => MARIADB_USER, "mariadb_passwd" => MARIADB_PASSWD}
end


