#!/bin/bash

yum -y install yum-utils vim net-tools

zbx_srv_installation() {

    hash_zbx_srv_conf="02d43c62d252393c294ce2d792b7bf45  /etc/zabbix/zabbix_server.conf"
    hash_zbx_conf="a7bf50a2b8d50fa25b555140d0272a84  /etc/httpd/conf.d/zabbix.conf"
    hash_httpd_conf="7c064196e073dac3f205d7555db66637  /etc/httpd/conf/httpd.conf"

 yum -y install mariadb mariadb-server
 systemctl enable mariadb
 systemctl start mariadb
 mysql -uroot -e "create database zabbix character set utf8 collate utf8_bin;"
 mysql -uroot -e "grant all privileges on zabbix.* to $mariadb_user@localhost identified by '$mariadb_passwd';"

 rpm -ivh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
 #yum-config-manager --enable rhel-7-server-optional-rpms
 yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-agent zabbix-get
 zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u$mariadb_user -p$mariadb_passwd zabbix

 # This is first configuration after installation,
 # so I decided repair created configs, instead of changing
 # But I used checking of hash => idempotency
 
 zbx_srv_conf() {
     cat >> /etc/zabbix/zabbix_server.conf << EOF
     DBHost=localhost
     DBPassword=$mariadb_passwd
EOF
 }
 zbx_conf() {
     sed -i 's-# php_value date.timezone Europe/Riga-php_value date.timezone Europe/Minsk-' /etc/httpd/conf.d/zabbix.conf
 }
 httpd_conf() {
     sed -i '43i Alias "/" "/usr/share/zabbix/"' /etc/httpd/conf/httpd.conf
 }

 [[ $(md5sum /etc/zabbix/zabbix_server.conf) != hash_zbx_srv_conf ]] && zbx_srv_conf
 [[ $(md5sum /etc/httpd/conf.d/zabbix.conf) != hash_zbx_conf ]] && zbx_conf
 [[ $(md5sum /etc/httpd/conf/httpd.conf) != hash_httpd_conf ]] && httpd_conf

 systemctl start zabbix-server
 systemctl enable zabbix-server

 systemctl start httpd
 systemctl enable httpd

 systemctl start zabbix-agent
 systemctl enable zabbix-agent

}

zbx_agent_installation() {
 
 rpm -ivh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
 #yum-config-manager --enable rhel-7-server-optional-rpms
 yum -y install zabbix-agent zabbix-sender

 systemctl start zabbix-agent
 systemctl enable zabbix-agent

 cat > /etc/zabbix/zabbix_agentd.conf << EOF
 PidFile=/var/run/zabbix/zabbix_agentd.pid
 LogFile=/var/log/zabbix/zabbix_agentd.log
 LogFileSize=0
 Server=$srv_ip
 ServerActive=$srv_ip
 Hostname=Zabbix server
 HostnameItem=system.hostname
 Include=/etc/zabbix/zabbix_agentd.d/*.conf
EOF
}

#Installation depends on hostname
[[ $(hostname) == "$srv_name" ]] && zbx_srv_installation || zbx_agent_installation
