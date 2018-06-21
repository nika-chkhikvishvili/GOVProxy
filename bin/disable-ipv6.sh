#!/bin/sh

# disable ipv6 on host
# part of govproxy
# Nika Chkhikvishvili 
# 2017
# License: GPLv2


node_ip=$1

if [[ -z "$node_ip" ]]; then 
   echo "no parameters supplied."
   echo "exiting.."
   exit 1

fi 


# check_if enebald:
if [[ $(cat /etc/default/grub | grep -c  ipv6.disable) -ne 0  ]]; then 
   echo  IPv6 is alerady disabled.
   echo skiping.
else

sed -i 's/GRUB_CMDLINE_LINUX\=\"/GRUB_CMDLINE_LINUX\=\"ipv6.disable=1 /g' /etc/default/grub
echo "making kernel changes permanent..."
   grub2-mkconfig -o /boot/grub2/grub.cfg > /dev/null 2>&1 
echo "making changes in network stack..."
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >>/etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' >>/etc/sysctl.conf
echo "enforcing network stack changes..."
sysctl -p > /dev/null 2>&1
echo "IPv6 has been successfully disabled on host: $node_ip"
fi 

