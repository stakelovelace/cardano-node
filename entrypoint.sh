#!/bin/bash

echo "NETWORK: $NETWORK $POOL_NAME";
. ~/.bashrc

export CNODE_HOME=/opt/cardano/cnode
export CNODE_PORT=6000

echo "NODE: $HOSTNAME - Port:$CNODE_PORT - $POOL_NAME";
cardano-node --version;

sudo touch /etc/crontab /etc/cron.*/*
sudo cron  > /dev/null 2>&1
#sudo /etc/init.d/promtail start > /dev/null 2>&1

dbsize=$(du -s ${CNODE_HOME}/db | awk '{print $1}')
tnsizedb=$(du -s $CNODE_HOME/priv/testnet-db 2>/dev/null | awk '{print $1}')
mnsizedb=$(du -s $CNODE_HOME/priv/mainnet-db 2>/dev/null | awk '{print $1}')

if [[ $dbsize < $mnsizedb ]] && [[ $NETWORK == "mainnet" ]]; then
cp -rf $CNODE_HOME/priv/mainnet-db/* ${CNODE_HOME}/db 2>/dev/null
fi

if [[ $dbsize < $tnsizedb ]] && [[ $NETWORK == "testnet" ]] ; then
cp -rf $CNODE_HOME/priv/testnet-db/* ${CNODE_HOME}/db 2>/dev/null
fi

# EKG Exposed
#socat -d tcp-listen:12782,reuseaddr,fork tcp:127.0.0.1:12781 

if [[ "$NETWORK" == "mainnet" ]]; then
  export TOPOLOGY="$CNODE_HOME/priv/files/mainnet-topology.json" \
  && export CONFIG="$CNODE_HOME/priv/files/mainnet-config.json" \
  && exec $CNODE_HOME/scripts/cnode.sh
elif [[ "$NETWORK" == "testnet" ]]; then
  export TOPOLOGY="$CNODE_HOME/priv/files/testnet-topology.json" \
  && export CONFIG="$CNODE_HOME/priv/files/testnet-config.json" \
  && exec $CNODE_HOME/scripts/cnode.sh
elif [[ "$NETWORK" == "launchpad" ]]; then
  export TOPOLOGY="$CNODE_HOME/priv/files/launchpad-topology.json" \
  && export CONFIG="$CNODE_HOME/priv/files/launchpad-config.json" \
  && exec $CNODE_HOME/scripts/cnode.sh
elif [[ "$NETWORK" == "allegra" ]]; then
  export TOPOLOGY="$CNODE_HOME/priv/files/allegra-topology.json" \
  && export CONFIG="$CNODE_HOME/priv/files/allegra-config.json" \
  && exec $CNODE_HOME/scripts/cnode.sh
elif [[ "$NETWORK" == "guildnet" ]]; then
  export TOPOLOGY="$CNODE_HOME/priv/files/guildnet-topology.json" \
  && export CONFIG="${CNODE_HOME}/files/config.json" \
  && sudo bash /home/guild/.scripts/guild-topology.sh > /dev/null 2>&1 \
  && exec $CNODE_HOME/scripts/cnode.sh
else
  echo "Please set a NETWORK environment variable to one of: mainnet / testnet / allegra / launchpad / guildnet"
  echo "mount a '$CNODE_HOME/priv/files' volume containing: mainnet-config.json, mainnet-shelley-genesis.json, mainnet-byron-genesis.json, and mainnet-topology.json "
  echo "for active nodes set POOL_DIR environment variable where op.cert, hot.skey and vrf.skey files reside. (usually under '${CNODE_HOME}/priv/pool/$POOL_NAME' ) "
  echo "or just set POOL_NAME environment variable (for default path). "
fi
