#!/bin/bash
 
export CNODE_HOME=/opt/cardano/cnode

curl -s -k -o /tmp/guild_topology2.json "https://api.clio.one/htopology/v1/fetch/?max=20"

cat /tmp/guild_topology2.json | awk '{print $3,$5}' | tail -n +2 | sed s/"\","//g  | sed s/"\""//g | sed s/","//g | grep -v [a-z] >  /tmp/guild_list1              

IFS=$'\n'; for i in $(cat /tmp/guild_list1 ); do sudo tcpping -x 1 $i | grep ms | awk '{print $9,$7}' >> /tmp/guild_list2 ; done
cat /tmp/guild_list2 | sort -n | grep -v "ms" | head -n 8 | cut -d "(" -f 2 | cut -d ")" -f 1   > /tmp/fastest_guild.list
 
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
AADD6=$(sed -n 6p /tmp/guild_list3 | awk '{print $1}')
AADD6PORT=$(sed -n 6p /tmp/guild_list3 | awk '{print $2}')
AADD7=$(sed -n 7p /tmp/guild_list3 | awk '{print $1}')
AADD7PORT=$(sed -n 7p /tmp/guild_list3 | awk '{print $2}')
AADD8=$(sed -n 8p /tmp/guild_list3 | awk '{print $1}')
AADD8PORT=$(sed -n 8p /tmp/guild_list3 | awk '{print $2}')
AADD9=$(sed -n 9p /tmp/guild_list3 | awk '{print $1}')
AADD9PORT=$(sed -n 9p /tmp/guild_list3 | awk '{print $2}')
AADD10=$(sed -n 10p /tmp/guild_list3 | awk '{print $1}')
AADD10PORT=$(sed -n 10p /tmp/guild_list3 | awk '{print $2}')

cat <<EOF > $CNODE_HOME/files/guildnet-topology.json
{ "resultcode": "201", "networkMagic": "764824073", "ipType":4, "Producers": [
  { "addr": "relays-new.cardano-mainnet.iohk.io", "port": 3001, "valency": 2, "distance":10 },
  { "addr": "172.31.0.51", "port": 6000, "valency": 3, "distance":10 },
  { "addr": "172.13.0.63", "port": 6000, "valency": 3, "distance":10 },
  { "addr": "78.47.99.41", "port": 6000, "valency": 2, "distance":10 },
  { "addr": "168.119.51.182", "port": 6000, "valency": 2, "distance":10 },
  { "addr": "95.216.207.178", "port": 6000, "valency": 2, "distance":10 },
  { "addr": "$AADD1", "port": $AADD1PORT, "valency": 1, "distance":10 },
  { "addr": "$AADD2", "port": $AADD2PORT, "valency": 1, "distance":10 },
  { "addr": "$AADD3", "port": $AADD3PORT, "valency": 1, "distance":10 },
  { "addr": "$AADD4", "port": $AADD4PORT, "valency": 1, "distance":10 },
  { "addr": "$AADD5", "port": $AADD5PORT, "valency": 1, "distance":10 },
  { "addr": "$AADD6", "port": $AADD6PORT, "valency": 1, "distance":10 },
  { "addr": "$AADD7", "port": $AADD7PORT, "valency": 1, "distance":10 },
  { "addr": "$AADD8", "port": $AADD8PORT, "valency": 1, "distance":10 },
  { "addr": "$AADD9", "port": $AADD9PORT, "valency": 1, "distance":10 },
  { "addr": "$AADD10", "port": $AADD10PORT, "valency": 1, "distance":10 }
] }
EOF

rm  /tmp/fastest_guild.list && rm /tmp/guild_list*
