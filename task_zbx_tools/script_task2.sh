#!/bin/bash

zabbix_sender -vv -z 192.168.56.106 -s "Zabbix server" -k "bob" -o "I want to test my trapper"
zabbix_get -s 192.168.56.107 -p 10050 -k system.cpu.load[all,avg1]