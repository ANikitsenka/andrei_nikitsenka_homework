#!/bin/bash

yum -y install yum-utils vim net-tools

elk_srv_installation() {
    
    elasticsearch_install() {
        wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.4.0-x86_64.rpm
        rpm -i elasticsearch-7.4.0-x86_64.rpm
    }
    kibana_install() {
        echo "[kibana-7.x]" >> /etc/yum.repos.d/kibana.repo
        echo "name=Kibana repository for 7.x packages" >> /etc/yum.repos.d/kibana.repo
        echo "baseurl=https://artifacts.elastic.co/packages/7.x/yum" >> /etc/yum.repos.d/kibana.repo
        echo "gpgcheck=1" >> /etc/yum.repos.d/kibana.repo
        echo "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch" >> /etc/yum.repos.d/kibana.repo
        echo "enabled=1" >> /etc/yum.repos.d/kibana.repo
        echo "autorefresh=1" >> /etc/yum.repos.d/kibana.repo
        echo "type=rpm-md" >> /etc/yum.repos.d/kibana.repo
        yum -y install kibana
    }
    kibana_config() {
        echo "server.port: 5601" >> /etc/kibana/kibana.yml
        echo "server.host: "$srv_ip"" >> /etc/kibana/kibana.yml
        echo "server.name: "$(hostname)"" >> /etc/kibana/kibana.yml
        echo 'elasticsearch.hosts: ["http://'$srv_ip:'9200"]' >> /etc/kibana/kibana.yml
        echo 'elasticsearch.username: "kibana"' >> /etc/kibana/kibana.yml
        echo 'elasticsearch.password: "pass"' >> /etc/kibana/kibana.yml
    }
    elasticsearch_config() {
        echo "network.host: $srv_ip" >> /etc/elasticsearch/elasticsearch.yml 
        echo "http.port: 9200" >> /etc/elasticsearch/elasticsearch.yml 
        echo 'discovery.seed_hosts: ["host1", "host2"]' >> /etc/elasticsearch/elasticsearch.yml 
        echo 'cluster.initial_master_nodes: ["node-1", "node-2"]' >> /etc/elasticsearch/elasticsearch.yml 
    }

    elasticsearch_install
    elasticsearch_config
    kibana_install
    kibana_config

    systemctl start elasticsearch
    systemctl enable elasticsearch
    systemctl start kibana
    systemctl enable kibana
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
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'
ExecStart=/opt/tomcat/bin/startup.sh
EOF

cat >> /etc/systemd/system/tomcat.service << \EOF
ExecStop=/bin/kill -15 $MAINPID
User=tomcat
Group=tomcat
[Install]
WantedBy=multi-user.target
EOF

cat > /opt/tomcat/conf/Catalina/localhost/manager.xml << EOF
<Context privileged="true" antiResourceLocking="false" 
         docBase="${catalina.home}/webapps/manager">
    <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="^.*$" />
</Context>
EOF


echo '<?xml version="1.0" encoding="UTF-8"?>' > /opt/tomcat/conf/tomcat-users.xml
echo '<tomcat-users xmlns="http://tomcat.apache.org/xml"' >> /opt/tomcat/conf/tomcat-users.xml
echo '              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' >> /opt/tomcat/conf/tomcat-users.xml
echo '              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"' >> /opt/tomcat/conf/tomcat-users.xml
echo '              version="1.0">' >> /opt/tomcat/conf/tomcat-users.xml
echo '<role rolename="admin-gui"/>' >> /opt/tomcat/conf/tomcat-users.xml
echo '<role rolename="manager-gui"/>' >> /opt/tomcat/conf/tomcat-users.xml
echo '<user username="tomcat" password="tomcat" roles="admin-gui,manager-gui"/>' >> /opt/tomcat/conf/tomcat-users.xml
echo '</tomcat-users>' >> /opt/tomcat/conf/tomcat-users.xml
 
    systemctl start tomcat
    systemctl enable tomcat
    systemctl status tomcat
    sleep 5
    }

    logstash_installation() {
        
        rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
        yum -y install logstash
        
        echo "[logstash-7.x]" >> /etc/yum.repos.d/logstash.repo
        echo "name=Elastic repository for 7.x packages" >> /etc/yum.repos.d/logstash.repo
        echo "baseurl=https://artifacts.elastic.co/packages/7.x/yum" >> /etc/yum.repos.d/logstash.repo
        echo "gpgcheck=1" >> /etc/yum.repos.d/logstash.repo
        echo "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch" >> /etc/yum.repos.d/logstash.repo
        echo "enabled=1" >> /etc/yum.repos.d/logstash.repo
        echo "autorefresh=1" >> /etc/yum.repos.d/logstash.repo
        echo "type=rpm-md" >> /etc/yum.repos.d/logstash.repo
        echo "logstash installation"

        echo "input {" > /etc/logstash/conf.d/logstash.conf
        echo "  file {" >> /etc/logstash/conf.d/logstash.conf
        echo '    path => "/opt/tomcat/logs/*.log"' >> /etc/logstash/conf.d/logstash.conf
        echo '    start_position => "beginning"' >> /etc/logstash/conf.d/logstash.conf
        echo "  }" >> /etc/logstash/conf.d/logstash.conf
        echo "}" >> /etc/logstash/conf.d/logstash.conf
        echo "" >> /etc/logstash/conf.d/logstash.conf
        echo "output {" >> /etc/logstash/conf.d/logstash.conf
        echo "  elasticsearch {" >> /etc/logstash/conf.d/logstash.conf
        echo '    hosts => ["'$srv_ip':9200"]' >> /etc/logstash/conf.d/logstash.conf
        echo '    index    => "tomcat-%{+YYYY.MM.dd}"' >> /etc/logstash/conf.d/logstash.conf
        echo "  }" >> /etc/logstash/conf.d/logstash.conf
        echo "  stdout { codec => rubydebug }" >> /etc/logstash/conf.d/logstash.conf
        echo "}" >> /etc/logstash/conf.d/logstash.conf

        chmod 744 -R /opt
    }

elk_node_installation() {
    tomcat_installation
    logstash_installation
    systemctl start logstash
    systemctl enable logstash
}

#Installation depends on hostname
[[ $(hostname) == "$srv_name" ]] && elk_srv_installation || elk_node_installation
