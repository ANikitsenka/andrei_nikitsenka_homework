#!/bin/bash

########################################## Task 1 ##########################################

create_worker_conf_file () {
cat << EOF > /etc/httpd/conf.d/mpm_worker_module.conf
<IfModule mpm_worker_module>
    ServerLimit          5
    StartServers         2
    MaxClients          25
    MinSpareThreads      5
    MaxSpareThreads     10
    ThreadsPerChild     10
</IfModule>
EOF
}

restart_httpd () {
systemctl status httpd
systemctl stop httpd
systemctl status httpd
systemctl start httpd
systemctl status httpd
}

#create_worker_conf_file
#restart_httpd

#Change LoadModule in /etc/httpd/conf.modules.d/00-mpm.conf to "mod_mpm_worker.so"

#Stop httpd server and configure non-threaded httpd server (i.e., prefork). Set server fqdn to prefork.name.surname

#systemctl stop httpd

#Change LoadModule in /etc/httpd/conf.modules.d/00-mpm.conf to "mod_mpm_prefork.so"
create_prefork_conf_file () {
cat << EOF > /etc/httpd/conf.d/mpm_prefork_module.conf
<IfModule mpm_prefork_module>
    ServerLimit           25
    StartServers           2
    MinSpareServers        3
    MaxSpareServers        5
    MaxClients            25
</IfModule>
EOF
}

#create_prefork_conf_file
#restart_httpd

######################################### Task 2 ###########################################

#Delete RewriteRules from /etc/httpd/conf.d/httpd-vhosts.conf

#Configure FORWARD proxy
create_proxy_conf_file () {
cat << EOF > /etc/httpd/conf.d/proxy.conf
ProxyRequests On
ProxyVia On
<Proxy *>
    Order allow,deny
    Allow from all
    AuthType Basic
    AuthName "Password Required"
    AuthUserFile /etc/httpd/conf/.htpasswd
    Require valid-user
</Proxy>
EOF
}
#create_proxy_conf_file

#Configure REVERSE proxy
create_proxy_rev_file () {
cat << EOF > /etc/httpd/conf.d/proxy_rev.conf
    ServerName reverse.andrei.nikitsenka

    ProxyRequests off
    ProxyPass /test  http://andrei.nikitsenka/index.html
    ProxyPassReverse /test  http://andrei.nikitsenka/index.html
EOF
}
#create_proxy_rev_file




