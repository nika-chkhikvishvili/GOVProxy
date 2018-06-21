#!/bin/sh

# global stuff
IFS=$'\n'
# include configuration variables
source /etc/govproxy/govproxy.conf
# setting temporary eexcution directory
tmp_dir=$(mktemp -d)

# Get access mode
 if [ -z "$proxy" ]; then 
    outgoing_method=direct
 else
    outgoing_method=proxy
fi


# main process
# get Pending nodes from database
pending_nodes=$(mysql -u $db_user  --raw -N -s -e "select * from $db_name.nodes where status=\"pending\";")

if [[ -z "$pending_nodes" ]]; then
   echo "No nodes pending"
   exit 1
fi


# get raw node infro from db
for  node in $pending_nodes;
  do
# adjust variables

# clear array
unset org_nat_ip_arr[@]

# parsing variables
node_ip=$(echo "$node" | awk '{print $2}')
node_ip_arr=("${node_ip_arr[@]}" "$node_ip" )
node_passwd=$(echo "$node" |awk '{print $8}')
node_dir="$tmp_dir/$node_ip"
mkdir $node_dir


# roll back 
function rollback () {
echo rolling back $org_alias config...
local_undo_rules=$(ssh $node_ip "ls /etc/govproxy/localconf/net-rules/rollback/*")

if [[ ! -z "$local_undo_rules" ]]; then
      for undo in $local_undo_rules;
        do 
           echo undoing rule: $undo on $node_ip
           # executing rule undo on node
           ssh $node_ip "/sbin/govproxy-net $undo" >/dev/null 2>&1
               if [ $? -eq 0  ]; then
                  echo "rule: $undo rollback DONE."
               else
                  echo "RULE: $undo rollback  FAILED"
                  exit 1
                fi
       done
else
                   echo "local undo rules is empty"
                   exit 1
fi

ssh $node_ip "rm -rf /etc/govproxy/"
ssh $node_ip "rm -rf  /etc/squid/conf.d/[!dummy]*"
ssh $node_ip "systemctl stop govproxy-net.service"
ssh $node_ip "systemctl disable govproxy-net.service"
ssh $node_ip "rm -rf /etc/systemd/system/multi-user.target.wants/govproxy-net.service"
echo "$node_ip: all clear."
echo "done rollback on node $node_ip"
exit 1
}

# add public key to node

sshpass -p $node_passwd ssh-copy-id -f -oStrictHostKeyChecking=no -oLogLevel='quiet'  $node_ip  >/dev/null 2>&1

  if [ $? -ne 0 ]; then 
     echo "unable to connect host $node_ip."
     exit 1
  fi




echo "setting update parameters"

if [[ "$outgoing_method" == "proxy" ]]; then 
    ssh  $node_ip 'if [ $(grep proxy -c /etc/yum.conf) -eq 1 ]; then sed -i '"s#proxy.*#proxy=http://$proxy:$proxy_port#g"' /etc/yum.conf; else echo '"proxy=http://${proxy}:${proxy_port}/"' >> /etc/yum.conf; fi'
fi

# update system
 ansible-playbook $playbooks_dir/update.yml --limit $node_ip
# install all neccesery packages
 ansible-playbook $playbooks_dir/install-packages.yml --limit $node_ip
exit
     
# push initial node config 
   echo "executining initial configurtaion on node $node_ip"
   echo "disabling IPv6 on host: $node_ip ..."
   ssh $node_ip "bash -s" < $BIN_PATH/disable-ipv6.sh $node_ip
 #  scp -rp /etc/govproxy/templates/* $node_ip:/  
 ansible-playbook /var/www/html/bin/playbooks/deploy-git.yml --limit $node_ip 
   ssh  $node_ip "chmod +x /sbin/govproxy-net"
   ssh $node_ip "systemctl enable govproxy-net.service"
   ssh $node_ip /sbin/govproxy-net /etc/govproxy/localconf/net-rules/dummy.netconf
   echo "stop"
   if [ $? -ne 0 ]; then
      echo "something wrong with $node_ip systemd."
       rollback
   fi
# restoring SELinux attributes
   restorecon -vFFR /etc/govproxy/
   restorecon -vFFR /etc/hosts
   restorecon -vFFR /sbin/
   



# assuming that trunk interface name is ens224
dev=ens224






# select organizations
organizations=$(mysql -u $db_user  --raw -N -s -e "select org_alias,org_net_pool,org_nat_range,org_vlan,org_gw,org_uuid,id,org_nat_mask\
                                                    from $db_name.org\
                                                         where org_status=\"active\" and IPPool_state=\"active\";")
for org in $organizations;
  do

    org_uuid=$(echo "$org" | awk '{print $6}')   
    org_alias=$(echo "$org" | awk '{print $1}')

   
  check_existing_node=$(mysql -u $db_user  --raw -N -s -e "SELECT IF
                                                              (EXISTS(select * from $db_name.IPPool where node_ip = '$node_ip' and org_uuid='$org_uuid'),1,0)
                                                                AS result";)

# check if node allreay exists in some org
if [ $check_existing_node -eq 0 ]; then

     
  # organization alias for routing table name
     # get organization UUID
    org_uuid=$(echo "$org" | awk '{print $6}')
    org_id=$(echo "$org" | awk '{print $7}')
    org_nat_mask=$(echo "$org" | awk '{print $8}')
    org_alias=$(echo "$org" | awk '{print $1}')
    # organization network
    org_net_pool=$(echo "$org" | awk '{print $2}')
    # organization vlan
    org_vlan=$(echo "$org" | awk '{print $4}')
    # organization gateway
    org_gw=$(echo "$org" | awk '{print $5}')
    # get organization NAT network range
    org_nat_network=$(echo "$org" | awk '{print $3}' |  cut -d . -f-3)
    # Get start IP from range
    org_nat_start_ip=$(echo "$org" | awk '{print $3}' |  cut -d . -f4 | cut -d - -f1)
    # generate org_nat_ip
    org_nat_ip=$(mysql -u $db_user  --raw -N -s -e "SELECT ip FROM $db_name.IPPool WHERE status=0 and org_uuid='$org_uuid' order by id asc limit 1";)
#####   org_nat_ip="$org_nat_network.$org_nat_start_ip"
    # Get end IP from range
    org_nat_end_ip=$(echo "$org" | awk '{print $3}' |  cut -d . -f4 | cut -d - -f2)
    # calculate NEXT start IP for DB update
   ###### org_nat_next_ip="$org_nat_network.$((org_nat_start_ip+1))-$org_nat_end_ip"
    org_netmask=$(echo $org_net_pool | cut -d\/ -f2)
    org_nat_ip_arr=("${org_nat_ip_arr[@]}" "$org_alias:$org_nat_ip" )
    org_brd=$(ipcalc -s -b $org_nat_network.$org_nat_start_ip/$org_nat_mask | cut -d\=  -f2)


echo "org_nat_ip: $org_nat_ip"
echo "org_nat_mask: $org_nat_mask"
sleep 3

# generate network config for org    
conf_tmp=$node_dir/$org_alias.netconf
undo_tmp=$node_dir/$org_alias.undo
squid_org_conf=$node_dir/$org_alias.conf

echo "conf_tmp: $conf_tmp"

# generate network config for org

echo "
# generated on: $(date)
# generated net config for $node_ip

# adding network interface $org_alias
ip link add link $dev name $org_alias type vlan id $org_vlan
ip addr add $org_nat_ip/$org_nat_mask  brd $org_brd dev $org_alias
ip link set dev $org_alias up
sleep 4
echo "inserting Table ID in rt_tables"
sleep 2
echo \"$org_id   $org_alias\" >> /etc/iproute2/rt_tables
ip route add default via $org_gw dev $org_alias table $org_alias
ip rule add from $org_nat_ip table $org_alias
ip rule add to $org_nat_ip table $org_alias
">$conf_tmp


echo "
# generated on: $(date)
# generated undo config for $node_ip

ip rule del from $org_nat_ip table $org_alias
ip rule del to $org_nat_ip table $org_alias
ip route del default via $org_gw dev $org_alias table $org_alias
sed -i '/$org_alias/d'  /etc/iproute2/rt_tables
ip link set dev $org_alias down
ip link delete $org_alias
">$undo_tmp


echo "


# for local check
acl $org_alias src $org_nat_ip/32
acl $org_alias src $org_net_pool
tcp_outgoing_address $org_nat_ip $org_alias

acl ${org_alias}_iface src $org_nat_ip/32
http_access allow  ${org_alias}_iface


">$squid_org_conf



echo "
conf_tmp: $conf_tmp
undo_tmp: $undo_tmp
squid_org_conf: $squid_org_conf
echo node_ip: $node_ip
"


echo "copying network/squid configs to the: $node_ip"
# push configs to node
   scp   $node_dir/*.netconf $node_ip:/etc/govproxy/localconf/net-rules/
   scp   $node_dir/*.undo  $node_ip:/etc/govproxy/localconf/net-rules/rollback/
   scp   $node_dir/*.conf  $node_ip:/etc/squid/conf.d



echo "echo executing network config rules on: $node_ip"
# check config rules
  ssh $node_ip "/sbin/govproxy-net /etc/govproxy/localconf/net-rules/$org_alias.netconf"
  sleep 3
  if [ $? -eq 0  ]; then 
        
      echo "rule: $conf_tmp is pushed successfully. OK"
      echo "pinging $org_alias gateway $org_gw:"
      ssh $node_ip "ping $org_gw -c5"
  else
     echo "rule: $conf_tmp reported ERR"
     rollback
  fi    





# check and compare outgoing ip
echo "executing IP MATCH..."
curl_output=$(ssh $node_ip "curl --connect-timeout 5 -s -A 'smart' --interface $org_alias ifconfig.co")
      if [[ "$curl_output" == $org_nat_ip ]]; then
          echo "curl output: $org_nat_ip matches with org interface IP: $org_nat_ip OK"
      else
         echo "curl output: $curl_output doesn't match interface IP: $org_nat_ip ERR"
         echo "rolling back node add  operation"
         rollback
fi

else
 echo "Node $node_ip is already exist in organization: $org_alias. skipping..."
fi

echo "updating database addigning: $org_nat_ip to $node_ip"
# update database set used ips
mysql -u $db_user  --raw -N -s -e "update $db_name.IPPool set status=1, node_ip='$node_ip' where ip='$org_nat_ip' and org_uuid='$org_uuid'";



done


sh $BIN_PATH/check-squid-out.sh ${node_ip}@${org_nat_ip_arr[@]}
if [ $? -ne 0 ]; then
    exit 1
  fi




sh  $BIN_PATH/propagete-on-lbs.sh "${node_ip_arr[@]}"
if [ $? -ne 0 ]; then
    exit 1

  fi



# update database set used ips
mysql -u $db_user  --raw -N -s -e "update $db_name.IPPool set status=1, node_ip='$node_ip' where ip='$org_nat_ip' and org_uuid='$org_uuid'";
mysql -u $db_user  --raw -N -s -e "UPDATE $db_name.nodes SET status='active' WHERE node_ip=\"$node_ip\"";





done

