#!/bin/sh

IFS=$' '
args=$@


echo $@>/tmp/dump





node_ip=$(echo $args | cut -d@ -f1)
org=$(echo $args | cut -d@ -f2)




function create_swap_dirs () {

  ssh $node_ip "mkdir /var/spool/squid"
  ssh $node_ip "chown squid:squid /var/spool/squid"
  ssh $node_ip "restorecon -vFFR /var/spool/squid"
  ssh $node_ip "squid -z"
}



if ssh $node_ip stat /var/spool/squid/swap.state \> /dev/null 2\>\&1
            then
                    echo "Swap directories probabky exist. skiping..."
            else
                    echo "Swap directories doesn't exist. creating..."
            create_swap_dirs
fi


# squid reload need some improvements
   echo "reloading SQUID on $node_ip ..."
   # yes because squid reload sucks at this moment.
   echo "stoping squid service..."
   ssh $node_ip  "squid -k shutdown -f /etc/squid/squid.conf"
   if [ $? -eq 0  ]; then
      for ((sec=15; sec>0; sec--))
        do
           echo -en "waiting squid: $sec\033[0K\r"
           sleep 1
        done
      echo "squid stoped successfully. OK"
  else
     echo "squid stop reported ERR"
     exit 1
  fi


   echo "start squid service..."
   ssh $node_ip  "systemctl start squid"
   if [ $? -eq 0  ]; then
      for ((sec=15; sec>0; sec--))
        do
           echo -en "waiting squid: $sec\033[0K\r"
           sleep 1
        done
      echo "squid stoped successfully. OK"
  else
     echo "squid stop reported ERR"
     exit 1
  fi



for param in $org;
  do


    org_alias=$(echo $param | cut -d: -f1)
    org_nat_ip=$(echo $param | cut -d: -f2)

     echo "executing SQUID config: ${org_alias}_.conf"
     for try in {1..5};
      do
     echo "connecting $node_ip" 
     curl_proxy_match=$(ssh $node_ip "curl -s --connect-timeout 3 -A 'smart' -x $org_nat_ip:3128  ifconfig.co")
     sleep 1
     done
   if [[ "$curl_proxy_match" == $org_nat_ip ]]; then
        echo "curl output: $org_nat_ip matches with SQUID interface IP: $org_nat_ip OK"
else
         echo "curl output: $curl_proxy_match doesn't match SQUID interface IP: $org_nat_ip ERR"
         echo "rolling back node add  operation"
         exit 1
fi

done
