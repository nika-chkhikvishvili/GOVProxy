#!/bin/sh

# part of govproxy
# agregate IPPool table according to node state.
# Nika Chkhikvishvili 
# 2017
# License: GPLv2



# global stuff
IFS=$'\n'
source /etc/govproxy/govproxy.conf




# select organizations
organizations=$(mysql -u $db_user  --raw -N -s -e "select org_alias,org_net_pool,org_nat_range,org_vlan,org_gw,org_uuid,id\
                                                    from $db_name.org\
                                                         where org_status=\"pending\" and IPPool_state=\"pending\";")

for org in $organizations;
  do


    org_nat_network=$(echo "$org" | awk '{print $3}' |  cut -d . -f-3)
    # Get start IP from range
    org_nat_start_ip=$(echo "$org" | awk '{print $3}' |  cut -d . -f4 | cut -d - -f1)
    # generate org_nat_ip
    org_nat_ip="$org_nat_network.$org_nat_start_ip"
    # Get end IP from range
    org_nat_end_ip=$(echo "$org" | awk '{print $3}' |  cut -d . -f4 | cut -d - -f2)
    # calculate NEXT start IP for DB update
    org_nat_next_ip="$org_nat_network.$((org_nat_start_ip+1))-$org_nat_end_ip"
    # get organization UUID
    org_uuid=$(echo "$org" | awk '{print $6}')

     
     for  (( ip=$org_nat_start_ip; ip<=$org_nat_end_ip; ip++))
         do  
             mysql -u $db_user  --raw -N -s -e "START TRANSACTION;\
                                                INSERT INTO $db_name.IPPool ( ip, status, org_uuid)\
                                                VALUES ( '$org_nat_network.$ip', 0, '$org_uuid');
                                                COMMIT;"
             if [ $? -ne 0 ]; then
              # mini rollback
               echo  "Error ocured while adding org $org_uuid addition."
               exit 1
             fi 
    # once insert was successfull update org IPPool status to active
     mysql -u $db_user  --raw -N -s -e "UPDATE $db_name.org SET IPPool_state='active'\
                                        WHERE org_uuid ='$org_uuid';"
 
     done

done



