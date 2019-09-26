#!/bin/bash

######################################## Task 1 ############################################

yum install -y epel-release tmux curl vim httpd gcc
sleep 1
yum install -y cronolog wget apr-devel apr-util apr-util-devel pcre pcre-devel

setenforce 0

create_index_httpd () {
cat << EOF > /var/www/html/index.html
<h2>Hello from httpd</h2>
<hr />
<p>Created by Andrei Nikitsenka</p>
EOF
}
create_index_httpd

config_fw_rules () {
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload
}
config_fw_rules

systemctl start httpd
echo "Please wait..."
sleep 3
httpd -S
systemctl stop httpd && echo "httpd stopped"

wget http://ftp.byfly.by/pub/apache.org//httpd/httpd-2.4.41.tar.gz -O /tmp/httpd-2.4.41.tar.gz
tar -xvf /tmp/httpd-2.4.41.tar.gz
rm -f /tmp/httpd-2.4.41.tar.gz

mkdir /apps
apache_install () {
home=$(pwd)
cd $home/httpd-2.4.41
./configure --prefix=/apps/httpd-2.4.41
make $home/httpd-2.4.41
make install
cd $home
}

creation_index_apache () {
cat << EOF > /apps/httpd-2.4.41/htdocs/index.html
<h2>Hello from Apache2</h2>
<hr />
<p>Created by Andrei Nikitsenka</p>
EOF
}
creation_index_apache


####################################### Task 2 ############################################

create_vhosts_conf () {
cat << EOF > /etc/httpd/conf.d/httpd-vhosts.conf
<VirtualHost *>
    ServerName www.andrei.nikitsenka
    ServerAlias andrei.nikitsenka
</VirtualHost>
EOF
}
create_vhosts_conf

add_vhosts_to_httpd_conf () {
echo "Include /etc/httpd/conf.d/httpd-vhosts.conf" >> /etc/httpd/conf/httpd.conf
} 
add_vhosts_to_httpd_conf

create_testpage () {
cat << EOF > /var/www/html/ping.html
<h2> This is ping.html </h2>
<hr />
<p>Created by Andrei Nikitsenka</p>
EOF
}
create_testpage

add_rwmod_rules () {
sed -i 's|</VirtualHost>||g' /etc/httpd/conf.d/httpd-vhosts.conf
echo "RewriteEngine On" >> /etc/httpd/conf.d/httpd-vhosts.conf
echo 'RewriteRule "/$" "/index.html" [R,L,NC]' >> /etc/httpd/conf.d/httpd-vhosts.conf
echo 'RewriteRule "^/index\.html$" "/ping.html" [R,L,NC]' >> /etc/httpd/conf.d/httpd-vhosts.conf
echo 'RewriteRule !^/ping - [F,NC]' >> /etc/httpd/conf.d/httpd-vhosts.conf
echo '</VirtualHost>' >> /etc/httpd/conf.d/httpd-vhosts.conf
}
add_rwmod_rules


######################################## Task 3 ###########################################

add_cronolog () {
mkdir -p /logs/httpd/andrei_nikitsenka
sed -i 's|</VirtualHost>||g' /etc/httpd/conf.d/httpd-vhosts.conf
echo '    ErrorLog "| /usr/sbin/cronolog /logs/httpd/andrei_nikitsenka/Version-error-%d%b%Y-log"' >> /etc/httpd/conf.d/httpd-vhosts.conf
echo '    CustomLog "| /usr/sbin/cronolog /logs/httpd/andrei_nikitsenka/Version-access-%d%b%Y-log" common' >> /etc/httpd/conf.d/httpd-vhosts.conf
echo '</VirtualHost>' >> /etc/httpd/conf.d/httpd-vhosts.conf
}
add_cronolog


######################################## Task 4 ###########################################

store_logs_to_syslog () {
sed -i 's|</VirtualHost>||g' /etc/httpd/conf.d/httpd-vhosts.conf
sed -i 's|.*ErrorLog.*||g' /etc/httpd/conf.d/httpd-vhosts.conf
sed -i 's|.*CustomLog.*||g' /etc/httpd/conf.d/httpd-vhosts.conf
echo '    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\"\%{User-agent}i\"" extended_ncsa' >> /etc/httpd/conf.d/httpd-vhosts.conf
echo '    ErrorLog  "| /usr/bin/logger -thttpd -plocal6.err"' >> /etc/httpd/conf.d/httpd-vhosts.conf
echo '    CustomLog "| /usr/bin/logger -thttpd -plocal6.notice" extended_ncsa' >> /etc/httpd/conf.d/httpd-vhosts.conf
echo '</VirtualHost>' >> /etc/httpd/conf.d/httpd-vhosts.conf
}
store_logs_to_syslog
