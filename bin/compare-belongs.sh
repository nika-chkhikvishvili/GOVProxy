#!/bin/sh

# compare IP, Network and map to specifiec organiaztion
# Nika Chkhikvishvili
# Part of GOVProxy Project
# License GPLv2


source /etc/govproxy/govproxy.conf

        total_users=$1
        total_usr_tmp=$2


echo "$total_usr_tmp" >>/opt/tmp.txt
cp $total_usr_tmp /opt/



mysql_raw_output=$(mysql  -u $db_user --default-character-set=utf8 --raw -N -s -e "select CONCAT_WS('|',org_name,org_net_pool) FROM $db_name.org WHERE (org_status=\"active\" OR org_status=\"reserved\");")


IFS=$'\n'

    for entry in $mysql_raw_output;
     do 
        org_net_pool=$(echo $entry | cut -d\| -f2 )
        org_name=$(echo $entry | cut -d\| -f1 )
        count=$(cat "$total_usr_tmp" | grepcidr -c -e "$org_net_pool" )
        org_percentage=$(calc -p "round($count*100/$total_users)")
       # echo "org_percentage: $org_name $org_percentage"
            if [ $? -ne 1 ]; then 
              echo "['$org_name[$count]', $org_percentage],"    
            fi
         count=""
   done

