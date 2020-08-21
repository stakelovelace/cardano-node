#!/bin/bash
 
export CNODE_HOME=/opt/cardano/cnode

touch /tmp/ip2trace_in.log && rm /tmp/ip2trace_in.log
touch /tmp/ip2trace_out.log && rm /tmp/ip2trace_out.log 

pHOST=$HOSTNAME
pIP=$(ifconfig eth0  | grep inet | awk '{print $2}')
pPORT=$(cat /home/guild/entrypoint.sh | grep "CNODE_PORT=" | cut -d "=" -f 2)

netstat -nt  | grep tcp | grep EST | grep "$pIP:$pPORT" | awk '{ print $5 }' | cut -d ':' -f 1 | grep -v 172 > /tmp/iptrace_list_in.csv
netstat -nt  | grep tcp | grep EST | grep "$pIP:$pPORT" | awk '{ print $5 }' | cut -d ':' -f 1 | grep 172 > /tmp/iptrace_list_in_local.csv
netstat -nt  | grep tcp | grep EST | grep -v "$pIP:$pPORT" | awk '{ print $5 }' | cut -d ':' -f 1 | grep -v 172 > /tmp/iptrace_list_out.csv
netstat -nt  | grep tcp | grep EST | grep -v "$pIP:$pPORT" | awk '{ print $5 }' | cut -d ':' -f 1 | grep 172 > /tmp/iptrace_list_out_local.csv
sleep 3 2>&1; 

/usr/local/bin/ip2location -list /tmp/iptrace_list_in.csv -t all > /tmp/ip2trace_list_in.plog 2>&1
sleep 2;
/usr/local/bin/ip2location -list /tmp/iptrace_list_out.csv -t all > /tmp/ip2trace_list_out.plog 2>&1


LinesIN=$(cat /tmp/ip2trace_list_in.plog | wc -l)
LinesOUT=$(cat /tmp/ip2trace_list_out.plog | wc -l)
timestamp=$(date --rfc-3339=seconds)
for ((i=1;i<=$LinesIN;i++)); do ADD=$(sed -n "$i"p /tmp/ip2trace_list_in.plog); echo "timestamp=$timestamp,pHOST=$pHOST,pIP=$pIP,pPORT=$pPORT,app=$ADD" | sed s/" country_long"/",country_long"/g >> /tmp/ip2trace_in.log; done
for ((i=1;i<=$LinesOUT;i++)); do ADD=$(sed -n "$i"p /tmp/ip2trace_list_out.plog); echo "timestamp=$timestamp,pHOST=$pHOST,pIP=$pIP,pPORT=$pPORT,app=$ADD" | sed s/" country_long"/",country_long"/g >> /tmp/ip2trace_out.log; done

