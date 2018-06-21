#!/bin/sh



for server in 192.168.37.101 192.168.37.102 192.168.37.103 192.168.37.108; do 

echo "server: $server"

    scp -r changes/etc/squid/* $server:/etc/squid
    restorecon -vFFR /etc/squid
    ssh $server service squid restart
    sleep 5 
done 
