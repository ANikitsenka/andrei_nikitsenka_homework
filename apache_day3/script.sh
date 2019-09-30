#!/bin/bash/

#1. Setup apache2 web server VM with mod_jk module.
yum install httpd-devel apr apr-devel apr-util apr-util-devel gcc gcc-c++ make autoconf libtool
mkdir -p /opt/mod_jk/
cd /opt/mod_jk
wget http://ftp.byfly.by/pub/apache.org/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.46-src.tar.gz
tar -xvzf tomcat-connectors-1.2.46-src.tar.gz
cd tomcat-connectors-1.2.46-src/native
./configure --with-apxs=/usr/bin/apxs --enable-api-compatibility
make
libtool --finish /usr/lib64/httpd/modules
make install

#2. Setup 3 VMs with tomcat server and configure them. Tomcat instances surname-tomcat1, surname-tomcat2, surname-tomcat3.
yum -y install java-1.8.0-openjdk
groupadd tomcat
mkdir /opt/tomcat
useradd -s /bin/nologin -g tomcat -d /opt/tomcat tomcat

wget http://www-us.apache.org/dist/tomcat/tomcat-9/v9.0.26/bin/apache-tomcat-9.0.26.tar.gz
tar -zxvf apache-tomcat-9.0.26.tar.gz -C /opt/tomcat --strip-components=1

cd /opt/tomcat
chgrp -R tomcat conf
chmod g+rwx conf
chmod g+r conf/*
chown -R tomcat logs/ temp/ webapps/ work/

chgrp -R tomcat bin
chgrp -R tomcat lib
chmod g+rwx bin
chmod g+r bin/*

cat << EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target
[Service]
Type=forking
Environment=JAVA_HOME=/usr/lib/jvm/jre
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/bin/kill -15 $MAINPID
User=tomcat
Group=tomcat
[Install]
WantedBy=multi-user.target
EOF

systemctl start tomcat
systemctl enable tomcat

vim /opt/tomcat/conf/tomcat-users.xml
vim /opt/tomcat/manager/META-INF/context.xml
vim /opt/tomcat/host-manager/META-INF/context.xml

firewall-cmd --zone=public --permanent --add-port=8080/tcp
firewall-cmd --reload

#3. Add test.jsp from presentation to all tomcat servers.

vim /opt/tomcat/webapps/ROOT/test.jsp

#tomcat1 - create test.jsp page
cat << EOF > /opt/tomcat/webapps/test.jsp
<%
  session.setAttribute("a","a");
%>
<html>
<head>
<title>Test JSP</title>
</head> 
<body>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr bgcolor="#CCCCCC">
    <td width="13%">TomcatA Machine</td>
    <td width="87%">&nbsp;</td>
  </tr>
  <tr>
    <td>Session ID :</td>
    <td><%=session.getId()%></td>
  </tr>
</table>
</body>
</html>
EOF

#tomcat2 - create test.jsp page
cat << EOF > /opt/tomcat/webapps/ROOT/test.jsp
<%
  session.setAttribute("a","a");
%>
<html>
<head>
<title>Test JSP</title>
</head> 
<body>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr bgcolor="#CCCC00">
    <td width="13%">TomcatB Machine</td>
    <td width="87%">&nbsp;</td>
  </tr>
  <tr>
    <td>Session ID :</td>
    <td><%=session.getId()%></td>
  </tr>
</table>
</body>
</html>
EOF

#tomcat3 - create test.jsp page
cat << EOF > /opt/tomcat/webapps/ROOT/test.jsp
<%
  session.setAttribute("a","a");
%>
<html>
<head>
<title>Test JSP</title>
</head> 
<body>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr bgcolor="#00CCCC">
    <td width="13%">TomcatC Machine</td>
    <td width="87%">&nbsp;</td>
  </tr>
  <tr>
    <td>Session ID :</td>
    <td><%=session.getId()%></td>
  </tr>
</table>
</body>
</html>
EOF

cat << EOF > /opt/tomcat/conf/Catalina/localhost/ROOT.xml
<Context 
  docBase="/opt/mywebapps/clusterjsp.war" 
  path="" 
  reloadable="true" 
/>
EOF

###Task2
#Configure mod_jk – worker.propertieas
cat << EOF > /etc/httpd/conf/workers.properties
worker.list=nikitsenka-cluster,nikitsenka-tomcat1,nikitsenka-tomcat2,nikitsenka-tomcat3

worker.nikitsenka-tomcat1.type=ajp13
worker.nikitsenka-tomcat1.port=8009
worker.nikitsenka-tomcat1.host=10.6.145.59
worker.nikitsenka-tomcat1.lbfactor=10

worker.nikitsenka-tomcat2.type=ajp13
worker.nikitsenka-tomcat2.port=8009
worker.nikitsenka-tomcat2.host=10.6.145.66
worker.nikitsenka-tomcat2.lbfactor=10

worker.nikitsenka-tomcat3.type=ajp13
worker.nikitsenka-tomcat3.port=8009
worker.nikitsenka-tomcat3.host=10.6.144.97
worker.nikitsenka-tomcat3.lbfactor=10

worker.nikitsenka-cluster.type=lb
worker.nikitsenka-cluster.balanced_workers=nikitsenka-tomcat1,nikitsenka-tomcat2,nikitsenka-tomcat3
worker.nikitsenka-cluster.sticky_session=1

EOF

#Create /etc/httpd/conf/mod-jk.conf for connect module with server
cat << EOF > /etc/httpd/conf/mod-jk.conf
LoadModule    jk_module  modules/mod_jk.so
JkWorkersFile conf/workers.properties
JkLogFile     logs/mod_jk.log
JkLogLevel    emerg
JkLogStampFormat "[%a %b %d %H:%M:%S %Y] "
JkOptions     +ForwardKeySize +ForwardURICompat -ForwardDirectories
JkRequestLogFormat     "%w %V %T"
EOF

firewall-cmd --zone=public --permanent --add-port=8009/tcp
firewall-cmd --reload


cat << EOF > /etc/httpd/conf.d/cluster.conf
<VirtualHost *:80>
    ServerName nikitsenka-cluster.lab
    JkMount  /* nikitsenka-cluster
</VirtualHost>

<VirtualHost *:80>
    ServerName nikitsenka-tomcat1.lab
    JkMount  /* nikitsenka-tomcat1
</VirtualHost>

<VirtualHost *:80>
    ServerName nikitsenka-tomcat2.lab
    JkMount  /* nikitsenka-tomcat2
</VirtualHost>

<VirtualHost *:80>
    ServerName nikitsenka-tomcat3.lab
    JkMount  /* nikitsenka-tomcat3
</VirtualHost>
EOF

###Task3

#Download log4j2

wget http://ftp.byfly.by/pub/apache.org/logging/log4j/2.12.1/apache-log4j-2.12.1-bin.tar.gz

tar -xvzf apache-log4j-2.12.1-bin.tar.gz -C /opt/tomcat/lib
mv * /opt/tomcat/lib
rm -rf apache-log4j-2.12.1-bin

#Create script setenv.sh
cat << EOF > /opt/tomcat/bin/setenv.sh
LOG4J_JARS="log4j-core-2.12.1.jar log4j-api-2.12.1.jar log4j-jul-2.12.1.jar"
#make log4j2.xml available
if [ ! -z "$CLASSPATH" ] ; then CLASSPATH="$CLASSPATH": ; fi
CLASSPATH="$CLASSPATH""$CATALINA_BASE"/lib
#Add log4j2 jar files to CLASSPATH
for jar in $LOG4J_JARS ; do
  if [ -r "$CATALINA_HOME"/lib/"$jar" ] ; then
    CLASSPATH="$CLASSPATH":"$CATALINA_HOME"/lib/"$jar"
  else
    echo "Cannot find $CATALINA_HOME/lib/$jar"
    echo "This file is needed to properly configure log4j2 for this program"
    exit 1
  fi
done
#use the logging manager from log4j-jul
LOGGING_MANAGER="-Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager"
LOGGING_CONFIG="-Dlog4j.configurationFile=${CATALINA_BASE}/conf/log4j2.xml"
EOF

chmod +x setenv.sh

#Delete the file /opt/tomcat/conf/logging.properties 
rm -rf catalina.properties 

#Create a file called log4j2.xml into /opt/tomcat/conf:
cat << EOF > /opt/tomcat/conf/log4j2.xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="warn" name="catalina" packages="">
    <Appenders>
        <RollingRandomAccessFile name="catalina"
            fileName="${sys:catalina.base}/logs/nikitsenka.log"
            filePattern="${sys:catalina.base}/logs/nikitsenka/$${date:yyyy-MM}/nikitsenka-%d{yyyy-MM-dd}-%i.log.zip">
            <PatternLayout>
                <Pattern>%d{MMM d, yyyy HH:mm:ss}: %5p (%F:%L) - %m%n</Pattern>
            </PatternLayout>
            <Policies>
                <TimeBasedTriggeringPolicy />
                <SizeBasedTriggeringPolicy size="250 MB" />
            </Policies>
            <DefaultRolloverStrategy max="100" />
        </RollingRandomAccessFile>
    </Appenders>
    <Loggers>
        <!-- default loglevel for emaxx code -->
        <logger name="org.apache.catalina" level="info">
            <appender-ref ref="catalina" />
        </logger>
        <Root level="info">
            <appender-ref ref="catalina" />
        </Root>
    </Loggers>
</Configuration>
EOF

/opt/tomcat/bin/startup.sh




