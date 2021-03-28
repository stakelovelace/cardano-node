#!/bin/bash

#set -e
#set -u
#set -o pipefail

trap 'killall -s SIGTERM cardano-node' SIGINT SIGTERM
# "docker run --init" to enable the docker init proxy
# To manually test: docker kill -s SIGTERM container

head -n 8 ~/.banner.txt

. ~/.bashrc > /dev/null 2>&1

echo "NETWORK: $NETWORK $POOL_NAME";

[[ -z "${CNODE_HOME}" ]] && export CNODE_HOME=/opt/cardano/cnode 
[[ -z "${CNODE_PORT}" ]] && export CNODE_PORT=6000


echo "NODE: $HOSTNAME - Port:$CNODE_PORT - $POOL_NAME";
cardano-node --version;

sudo /etc/init.d/promtail start > /dev/null 2>&1

dbsize=$(du -s ${CNODE_HOME}/db | awk '{print $1}')
bksizedb=$(du -s $CNODE_HOME/priv/$NETWORK-db 2>/dev/null | awk '{print $1}')

if [[ "$dbsize" -lt "$bksizedb" ]]; then
cp -rf $CNODE_HOME/priv/$NETWORK-db/* ${CNODE_HOME}/db 2>/dev/null
fi

if [[ "$dbsize" -gt "$bksizedb" ]]; then
cp -rf ${CNODE_HOME}/db/* $CNODE_HOME/priv/$NETWORK-db/ 2>/dev/null
fi

# EKG Exposed
if [[ "$EKG" == "Y" ]]; then
socat -d tcp-listen:12782,reuseaddr,fork tcp:127.0.0.1:12781 
fi

export UPDATE_CHECK='N'

if [[ "$NETWORK" == "mainnet" ]]; then
  $CNODE_HOME/scripts/prereqs.sh -n mainnet -t cnode -s -f > /dev/null 2>&1 \
  && exec $CNODE_HOME/scripts/cnode.sh
elif [[ "$NETWORK" == "testnet" ]]; then
  $CNODE_HOME/scripts/prereqs.sh -n testnet -t cnode -s -f > /dev/null 2>&1 \
  && exec $CNODE_HOME/scripts/cnode.sh
elif [[ "$NETWORK" == "guild-mainnet" ]]; then
  $CNODE_HOME/scripts/prereqs.sh -n mainnet -t cnode -s -f > /dev/null 2>&1 \
  && bash /home/guild/.scripts/guild-topology.sh > /dev/null 2>&1 \
  && exec $CNODE_HOME/scripts/cnode.sh
elif [[ "$NETWORK" == "guild" ]]; then
  $CNODE_HOME/scripts/prereqs.sh -n guild -t cnode -s -f > /dev/null 2>&1 \
  && exec $CNODE_HOME/scripts/cnode.sh
else
  echo "Please set a NETWORK environment variable to one of: mainnet / testnet / guild / guild-mainnet"
  echo "mount a '$CNODE_HOME/priv/files' volume containing: mainnet-config.json, mainnet-shelley-genesis.json, mainnet-byron-genesis.json, and mainnet-topology.json "
  echo "for active nodes set POOL_DIR environment variable where op.cert, hot.skey and vrf.skey files reside. (usually under '${CNODE_HOME}/priv/pool/$POOL_NAME' ) "
  echo "or just set POOL_NAME environment variable (for default path). "
fi

find /opt/cardano/cnode -name "*config*.json" -print0 | xargs -0 sed -i 's/127.0.0.1/0.0.0.0/g' 2> /dev/null 
find /opt/cardano/cnode -name "*config*.json" -print0 | xargs -0 sed -i 's/\"TraceMempool\": true/\"TraceMempool\": false/g' 2> /dev/null 
find /opt/cardano/cnode -name "cntools.config" -print0 | xargs -0 sed -i 's/ENABLE_CHATTR=true/ENABLE_CHATTR=false/g' 2> /dev/null 
