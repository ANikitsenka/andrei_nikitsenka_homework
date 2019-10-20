#!/bin/bash

yum -y install yum-utils vim net-tools

zbx_srv_installation() {

    hash_zbx_srv_conf="06685b3b37edf31edfeda827ccb8a98d  /etc/zabbix/zabbix_server.conf"
    hash_zbx_conf="a7bf50a2b8d50fa25b555140d0272a84  /etc/httpd/conf.d/zabbix.conf"
    hash_httpd_conf="7c064196e073dac3f205d7555db66637  /etc/httpd/conf/httpd.conf"

 yum -y install mariadb mariadb-server
 systemctl enable mariadb
 systemctl start mariadb
 mysql -uroot -e "create database zabbix character set utf8 collate utf8_bin;"
 mysql -uroot -e "grant all privileges on zabbix.* to $mariadb_user@localhost identified by '$mariadb_passwd';"

 rpm -ivh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
 #yum-config-manager --enable rhel-7-server-optional-rpms
 yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-agent zabbix-get zabbix-java-gateway
 zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u$mariadb_user -p$mariadb_passwd zabbix

 # This is first configuration after installation,
 # so I decided repair created configs, instead of changing
 # But I used checking of hash => idempotency
 
 zbx_srv_conf() {
     cat >> /etc/zabbix/zabbix_server.conf << EOF
     DBHost=localhost
     DBPassword=$mariadb_passwd
     JavaGateway=$srv_ip
     JavaGatewayPort=10052
     StartJavaPollers=5
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

 systemctl start zabbix-java-gateway
 systemctl enable zabbix-java-gateway

 systemctl start httpd
 systemctl enable httpd

 systemctl start zabbix-agent
 systemctl enable zabbix-agent

}

zbx_agent_installation() {
 
 rpm -ivh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
 #yum-config-manager --enable rhel-7-server-optional-rpms
 yum -y install zabbix-agent zabbix-sender

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

 systemctl start zabbix-agent
 systemctl enable zabbix-agent

}

 tomcat_installation() {
     
    yum -y install java-1.8.0-openjdk
    groupadd tomcat
    mkdir /opt/tomcat
    useradd -s /bin/nologin -g tomcat -d /opt/tomcat tomcat

    wget http://ftp.byfly.by/pub/apache.org/tomcat/tomcat-8/v8.5.47/bin/apache-tomcat-8.5.47.tar.gz
    tar -zxvf apache-tomcat-8.5.47.tar.gz -C /opt/tomcat --strip-components=1

    chmod g+rwx /opt/tomcat/*
    chown -R tomcat:tomcat /opt/tomcat
    sleep 3
    cp /vagrant/TestApp.war /opt/tomcat/webapps/

cat > /etc/systemd/system/tomcat.service << EOF 
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target
[Service]
Type=forking
Environment=JAVA_HOME=/usr/lib/jvm/jre/
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xss1024k -Xms256M -Xmx512M -server -XX:+UseParallelGC -verbose:gc -XX:+HeapDumpOnOutOfMemoryError -Xloggc:/opt/tomcat/logs/gclogs.txt'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=12345 -Dcom.sun.management.jmxremote.rmi.port=12346 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=$tomcat_ip'
ExecStart=/opt/tomcat/bin/startup.sh
EOF

cat >> /etc/systemd/system/tomcat.service << \EOF
ExecStop=/bin/kill -15 $MAINPID
User=tomcat
Group=tomcat
[Install]
WantedBy=multi-user.target
EOF
    
    wget http://repo2.maven.org/maven2/org/apache/tomcat/tomcat-catalina-jmx-remote/8.5.47/tomcat-catalina-jmx-remote-8.5.47.jar
    cp tomcat-catalina-jmx-remote-8.5.47.jar /opt/tomcat/lib

    add_listener_jmx() {
        listener_count=$(grep -nr '<Listener' /opt/tomcat/conf/server.xml | cut -d : -f 1 | tail -1)
        listener_count=$((listener_count+1))
        sed -i "${listener_count}i <Listener className='org.apache.catalina.mbeans.JmxRemoteLifecycleListener' rmiRegistryPortPlatform='8097' rmiServerPortPlatform='8098'/>" /opt/tomcat/conf/server.xml 
    }
    
    listener_jmx_check=$(grep 'className="org.apache.catalina.mbeans.JmxRemoteLifecycleListener"' /opt/tomcat/conf/server.xml)
    [[ $listener_jmx_check == "" ]] && add_listener_jmx

    systemctl start tomcat
    systemctl enable tomcat
    systemctl status tomcat
    }

zbx_agent_provision() {
    zbx_agent_installation
    tomcat_installation
}

#Installation depends on hostname
[[ $(hostname) == "$srv_name" ]] && zbx_srv_installation || zbx_agent_provision
