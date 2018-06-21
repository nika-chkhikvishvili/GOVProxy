#!/bin/sh

# part of govproxy helper 
# check if squid 'tcp_outgoing_address' matches to corresponding ip adress
# Nika Chkhikvishvili 
# 2017
# License: GPLv2



args=$@

for node_ip in $args; 
  do
   echo "NODE: $node_ip"


for conf in $(ssh $node_ip find  /etc/squid/conf.d/  -type f ! -name "dummy.conf" ); 

  do
      echo "examining: $conf on $node_ip"
      addr=$(ssh $node_ip cat $conf | grep tcp_outgoing_address | awk '{print $2}')
      org_alias=$(ssh $node_ip cat $conf | grep tcp_outgoing_address | awk '{print $3}')
      ifconfig_out=$(ssh $node_ip ifconfig $org_alias | grep inet | awk '{print $2}')
         if [[ "$addr" == "$ifconfig_out" ]] ;then 
            echo "ORG: $org_alias. IP addr: $addr is matches to $ifconfig_out"
            echo -e " \e[32mOK\e[0m"            	
           
         else
              echo "ORG: $org_alias. IP addr: $addr is not matches to $ifconfig_out" 
              echo -e "\e[31mERROR\e[0m"
              exit 1
          fi
  done

done

