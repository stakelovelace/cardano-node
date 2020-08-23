#!/bin/bash

# This script takes the first event identified as fisrt time block seen and stores it in a 5k file (/tmp/block_index.log) ready to be digested in our case by loki in grafana.
# 
# This script was built with the intent to use the guild_operators work (including cntools) ready out of the box.
#

grep headerHash /opt/cardano/cnode/logs/node-0.json | jq .data.block.headerHash | uniq | grep -v null | awk '{FS="\""; print $2}' > /tmp/block_list

for i in $(cat /tmp/block_list); do 
grep $i /tmp/block_index.idx; QRESU=$?; # Debug: echo "$QRESU - $i";
if [[ $QRESU -gt 0 ]]; then
    BLOCK=$(cat /opt/cardano/cnode/logs/node-0.json | grep $i | head -n 1); # Debug: echo "$BLOCK - $i";
    echo $BLOCK >> /tmp/block_index.log;
    echo $BLOCK >> /tmp/block_index.idx;
fi
done

tail -n 5000 /tmp/block_index.idx > /tmp/block_index.idx2
mv /tmp/block_index.idx2 /tmp/block_index.idx 

tail -n 5000 /tmp/block_index.log > /tmp/block_index.log2
mv /tmp/block_index.log2 /tmp/block_index.log
