#!/bin/bash
 
export CNODE_HOME=/opt/cardano/cnode

curl -s -o -k /tmp/guild_topology2.json "https://api.clio.one/htopology/v1/fetch/?max=20"

cat /tmp/guild_topology2.json | awk '{print $3,$5}' | tail -n +2 | sed s/"\","//g  | sed s/"\""//g | sed s/","//g | grep -v [a-z] >  /tmp/guild_list1              

IFS=$'\n'; for i in $(cat /tmp/guild_list1 ); do sudo tcpping -x 1 $i | grep ms | awk '{print $9,$7}' >> /tmp/guild_list2 ; done
cat /tmp/guild_list2 | sort -n | grep -v "ms" | head -n 5 | cut -d "(" -f 2 | cut -d ")" -f 1   > /tmp/fastest_guild.list
 
IFS=$'\n'; for i in $(cat /tmp/fastest_guild.list); do  cat /tmp/guild_list1 | grep "$i" >> /tmp/guild_list3; done


AADD1=$(sed -n 1p /tmp/guild_list3 | awk '{print $1}')
AADD1PORT=$(sed -n 1p /tmp/guild_list3 | awk '{print $2}')
AADD2=$(sed -n 2p /tmp/guild_list3 | awk '{print $1}')
AADD2PORT=$(sed -n 2p /tmp/guild_list3 | awk '{print $2}')
AADD3=$(sed -n 3p /tmp/guild_list3 | awk '{print $1}')
AADD3PORT=$(sed -n 3p /tmp/guild_list3 | awk '{print $2}')
AADD4=$(sed -n 4p /tmp/guild_list3 | awk '{print $1}')
AADD4PORT=$(sed -n 4p /tmp/guild_list3 | awk '{print $2}')
AADD5=$(sed -n 5p /tmp/guild_list3 | awk '{print $1}')
AADD5PORT=$(sed -n 5p /tmp/guild_list3 | awk '{print $2}')

cat <<EOF > $CNODE_HOME/priv/files/guild_topology.json
{ "resultcode": "201", "networkMagic": "764824073", "ipType":4, "Producers": [
  { "addr": "relays-new.cardano-mainnet.iohk.io", "port": 3001, "valency": 2, "distance":10 },
  { "addr": "172.31.0.55", "port": 6000, "valency": 3, "distance":10 },
  { "addr": "172.13.0.63", "port": 6000, "valency": 3, "distance":10 },
  { "addr": "$AADD1", "port": $AADD1PORT, "valency": 1, "distance":10 },
  { "addr": "$AADD2", "port": $AADD2PORT, "valency": 1, "distance":10 },
  { "addr": "$AADD3", "port": $AADD3PORT, "valency": 1, "distance":10 },
  { "addr": "$AADD4", "port": $AADD4PORT, "valency": 1, "distance":10 },
  { "addr": "$AADD5", "port": $AADD5PORT, "valency": 1, "distance":10 },
  { "addr": "78.47.99.41", "port": 6000, "valency": 1, "distance":10 },
  { "addr": "168.119.51.182", "port": 6000, "valency": 1, "distance":10 },
  { "addr": "159.69.185.211", "port": 6000, "valency": 1, "distance":10 }
] }
EOF

rm  /tmp/fastest_guild.list && rm /tmp/guild_list*
