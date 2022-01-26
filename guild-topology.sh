#!/bin/bash
 
export CNODE_HOME=/opt/cardano/cnode

if [[ $FASTTOPO ]] ; then 

wget -O dwtopology.json https://explorer.cardano.org/relays/topology.json > /dev/null 2>&1

if [[ $FASTTOPO ]] && [[ $COUNTRY ]] ; then

Download_country_list() {
echo  "Download_country_list $COUNTRY ";
cat dwtopology.json | jq -c '.[][]' | grep -v "148.72.153.168" | grep -v "194.233.79.155" | grep -v "173.224.124.85" | grep -v "62.138.3.118" | grep -v "85.25.159.219" | grep -v "85.25.159.221" | grep -v "85.25.105.92" | grep -i $COUNTRY | sed s/"{\"addr\":\""//g | sed 's/\",\"port\":/ /g' | cut -d "," -f 1 >> IOHK.topo 
echo  "Download $COUNTRY finished";
return 0
}


if [[ "$COUNTRY" == "auto" ]]; then COUNTRY=$(curl ipinfo.io | jq .country | sed 's/\"//g'); Download_country_list; elif [ $COUNTRY ] ; then echo "Country: $COUNTRY"; Download_country_list; fi

fi

if [[ $FASTTOPO ]] && [[ $CONTINENT ]] ; then

Download_continent_list() {
echo  "Download_continent_list $CONTINENT ";
cat dwtopology.json  | jq -c '.[][]' | grep -v "148.72.153.168" | grep -v "194.233.79.155" | grep -v "173.224.124.85" | grep -v "62.138.3.118" | grep -v "85.25.159.219" | grep -v "85.25.159.221" | grep -v "85.25.105.92" | grep -i "\"continent\":\".*$CONTINENT\"" | sed s/"{\"addr\":\""//g | sed 's/\",\"port\":/ /g' | cut -d "," -f 1 >> IOHK.topo 
echo  "Download $CONTINENT finished";
return 0
}



if [[ "$CONTINENT" == "auto" ]]; then CONTINENT=$(curl ipinfo.io | jq .timezone | sed 's/\"//g' | cut -d "/" -f 1); Download_continent_list; elif  [ $CONTINENT ] ; then echo "Continent: $CONTINENT"; Download_continent_list; fi

fi 

echo "Starting IP latency check $COUNTRY $CONTINENT";

IFS=$'\n'; for i in $(cat IOHK.topo); do sudo tcpping -x 1 $i | grep ms | awk '{print $9,$7}' >> /tmp/guild_list2 ; done

echo "Sorting IPs";
cat /tmp/guild_list2 | sort -n | grep -v "ms" | head -n 100 | cut -d "(" -f 2 | cut -d ")" -f 1   > /tmp/fastest_guild.list

echo "Parsing results  $COUNTRY $CONTINENT";
IFS=$'\n'; for i in $(cat /tmp/fastest_guild.list); do  cat dwtopology.json | jq -c '.[][]' | grep -i "$i" >> /tmp/guild_list3; done > /dev/null 2>&1 

echo "Create Topology  $COUNTRY $CONTINENT";

cat /tmp/guild_list3 | sort | uniq > /tmp/guild_list4
cat <<EOF > $CNODE_HOME/files/guildnet-topology.json1
{"Producers": [
{"addr": "148.72.153.168", "port": 16000, "valency": 1, "state":"AAA"},
{"addr": "148.72.153.168", "port": 8000, "valency": 2, "state":"AAA"},
{"addr": "78.47.99.41", "port": 6000, "valency": 1, "state":"AAA"},
{"addr": "168.119.51.182", "port": 6000, "valency": 1, "state":"AAA"},
{"addr": "95.216.207.178", "port": 6000, "valency": 1, "state":"AAA"},
{"addr": "85.25.105.92", "port": 6000, "valency": 1, "state":"AAA"},
{"addr": "194.233.79.155", "port": 6000, "valency": 1, "state":"AAA"},
{"addr": "62.138.3.118", "port": 8000, "valency": 2, "state":"AAA"},
{"addr": "85.25.159.221", "port": 6000, "valency": 1, "state":"AAA"},
{"addr": "85.25.159.219", "port": 6000, "valency": 1, "state":"AAA"},
EOF

IFS=$'\n'; for i in $(cat /tmp/guild_list4); do echo "$i," >> $CNODE_HOME/files/guildnet-topology.json1; done 
echo -e "{\"addr\": \"relays-new.cardano-mainnet.iohk.io\", \"port\": 3001, \"valency\": 2, \"state\":\"IOHK\"} \\n] }" >> $CNODE_HOME/files/guildnet-topology.json1
cat $CNODE_HOME/files/guildnet-topology.json1 | jq > $CNODE_HOME/files/guildnet-topology.json

cat  $CNODE_HOME/files/guildnet-topology.json2 | jq -c '.[][]' | wc -l

rm  IOHK.topo /tmp/guild_list2 /tmp/guild_list3 /tmp/guild_list4 $CNODE_HOME/files/guildnet-topology.json1 dwtopology.json


fi
