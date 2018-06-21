#!/bin/sh

# part of govproxy
# Delete Node from POOL
# Nika Chkhikvishvili 
# 2017
# License: GPLv2



# global stuff
IFS=$'\n'
source /etc/govproxy/govproxy.conf
tmp_dir=$(mktemp -d)


# main process
pending_nodes=$(mysql -u $db_user  --raw -N -s -e "select * from $db_name.nodes where status=\"del_pending\";")
# get raw node infro from db
for  node in $pending_nodes;
  do
# adjust variables

echo "deleting node: $node"

node_ip=$(echo "$node" | awk '{print $2}')
node_passwd=$(echo "$node" |awk '{print $8}')
node_dir="$tmp_dir/$node_ip"
mkdir $node_dir

echo "Node IP: $node_ip"
echo "Node: Pass: $node_passwd"
echo "Node dir: $node_dir"

echo "Removing configs on node: $node_ip ..."
local_undo_rules=$(ssh $node_ip "ls /etc/govproxy/localconf/net-rules/rollback/*")

if [[ ! -z "$local_undo_rules" ]]; then
      for undo in $local_undo_rules;
        do 
           echo undoing rule: $undo on $node_ip
           ssh $node_ip "/sbin/govproxy-net $undo" >/dev/null 2>&1
               if [ $? -eq 0  ]; then
                  echo "rule: $undo removing DONE."
               else
                  echo "RULE: $undo removing  FAILED"
                  exit 1
                fi
       done
else
                   echo "local undo rules is empty"
                   exit 1
fi

done

echo "disabling services..."
ssh $node_ip "systemctl stop gov-proxy-net.service"
ssh $node_ip "systemctl disable gov-proxy-net.service"
echo "removing files..."
ssh $node_ip "rm -rf "/etc/krb5.keytab  /etc/sysconfig/squid /etc/squid/facebook.conf \
        /etc/squid/kerberos-auth.conf /etc/squid/facebook-cache.conf \
        /etc/squid/group-matching.conf /etc/squid/ssl-bump.conf \
        /etc/govproxy/ /etc/squid/conf.d/ \
        /etc/systemd/system/multi-user.target.wants/gov-proxy-net.service"

echo "configs are successfuly removed from node: $node_ip"

echo "Freeing ORG IPs used by NODE: $node_ip"
mysql -u $db_user  --raw -N -s -e "UPDATE IPPool SET node_ip=\"\", status=0 WHERE node_ip=\"$node_ip\";" 
echo "DB is free from node config."




