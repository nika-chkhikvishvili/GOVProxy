#!/bin/sh

# part of govproxy
# propagate new added node on L4 Load balancer (ipvsadm/keepalived) 
# Nika Chkhikvishvili 
# 2017
# License: GPLv2



# global stuff

source /etc/govproxy/govproxy.conf
tmp_dir=$(mktemp -d)

node_ip=$@


lbs=$(mysql -u $db_user  --raw -N -s -e "select lb_ip from $db_name.lb_conf where lb_status=\"enabled\";")

  for lb_ip in $lbs; 
   do
    
# generate node config for lb     
echo "
! auto generated by govproxy
  real_server $node_ip 3128 {
        weight 1
        TCP_CHECK {
        connect_port 3128
        connect_timeout 3
        }
            }

">$tmp_dir/${node_ip}.conf       

# transfer & enable config
echo "lb config created at: $tmp_dir/${node_ip}.conf"
echo "transfering lb config on $lb_ip"
    scp $tmp_dir/${node_ip}.conf $lb_ip:/etc/keepalived/conf.d/
echo "enabling $node_ip config on $lb_ip"
    ssh $lb_ip "systemctl reload keepalived.service >/dev/null 2>&1" 
done

echo "checking LB for new node config."
echo "waiting for 5 seconds to check changes"
sleep 5

lb_vip=$(mysql -u $db_user  --raw -N -s -e "select lb_vip from $db_name.lb_conf where lb_status=\"enabled\" limit 1;"  )

# check config
    if [[ $(ssh $lb_vip "ipvsadm -L -n | grep -c $node_ip") -ne 1 ]]; then 
    
      echo "failed to reload config on VIP: $lb_vip"
      exit 1
    else
      echo "node config: ${node_ip}.conf has successfuli pushed to VIP: $lb_vip"
fi


