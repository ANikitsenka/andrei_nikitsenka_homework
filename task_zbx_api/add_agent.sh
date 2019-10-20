#!/bin/bash

zbx_usr="Admin"
zbx_pswd="zabbix"
zbx_host_grp="CloudHosts"
zbx_template="Custom_template"
zbx_agent_name="Zabbix_agent_API"
srv_api="http://192.168.56.106/api_jsonrpc.php"
srv_port="10050"
agent_ip=$(hostname -I | cut -d ' ' -f 2)

#Authenticate and get key from response
zbx_auth_request() {
    curl -i -X POST -H 'Content-Type: application/json-rpc' -d '{"jsonrpc": "2.0","method": "user.login","params": {"user": "'$zbx_usr'","password": "'$zbx_pswd'"},"id": 1}' $srv_api
}
zbx_auth_response=$(zbx_auth_request)
zbx_auth_key=$(echo $zbx_auth_response | cut -d '"' -f 8)

#Accordingly to the task we should check existence of group "CloudHosts"
zbx_hostgroup_check() {
    curl -i -X POST -H 'Content-Type: application/json-rpc' -d '{"jsonrpc": "2.0","method": "hostgroup.get","params": {"output": "extend","filter": {"name": "'$zbx_host_grp'"}},"auth": "'$zbx_auth_key'","id": 1}' $srv_api
}
zbx_hostgroup_check_response=$(zbx_hostgroup_check)
#If group isn't exist, value below =':[],'
test_nonexist_grp=$(echo $zbx_hostgroup_check_response | cut -d '"' -f 7)

#Create hostgroup and get id of group from response
zbx_hostgroup_create() {
    curl -i -X POST -H 'Content-Type: application/json-rpc' -d '{"jsonrpc": "2.0","method": "hostgroup.create","params": {"name": "'$zbx_host_grp'"},"auth": "'$zbx_auth_key'","id": 1}' $srv_api
}
# Condition. Create or use exist group with certain name
[[ $test_nonexist_grp == ':[],' ]] && zbx_hostgroup_create_response=$(zbx_hostgroup_create) || zbx_hostgroup_create_response=$zbx_hostgroup_check_response
# Get ID from response of created or exist group
zbx_grp_id=$(echo $zbx_hostgroup_create_response | cut -d '"' -f 10)

#Create custom template
zbx_template_create() {
    curl -i -X POST -H 'Content-Type: application/json-rpc' -d '{"jsonrpc": "2.0","method": "template.create","params": {"host": "'$zbx_template'" , "groups": {"groupid": "'$zbx_grp_id'"}},"auth": "'$zbx_auth_key'","id": 1}' $srv_api
}
zbx_template_create_response=$(zbx_template_create)
zbx_template_id=$( echo $zbx_template_create_response | cut -d '"' -f 10)

#Finally, create host
zbx_create_host() {
    curl -i -X POST -H 'Content-Type: application/json-rpc' -d '{"jsonrpc": "2.0","method": "host.create","params": {"host": "'$zbx_agent_name'","interfaces": [{"type": 1,"main": 1,"useip": 1,"ip": "'$agent_ip'","dns": "","port": "'$srv_port'"}],"groups": [{"groupid": "'$zbx_grp_id'"}],"templates": [{"templateid": "'$zbx_template_id'"}]},"auth": "'$zbx_auth_key'","id": 1}' $srv_api
}
zbx_create_host_response=$(zbx_create_host)
zbx_host_id=$( echo $zbx_create_host_response | cut -d '"' -f 10)
echo "New host $zbx_agent_name was successfully added to the Zabbix-server with id=$zbx_host_id"