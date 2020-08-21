#!/bin/bash

echo "NETWORK: $NETWORK";
. ~/.bashrc

export CNODE_HOME=/opt/cardano/cnode 
export CNODE_PORT=6000
export POOL=$@ 

echo "NODE:";
cardano-node --version;

sudo touch /etc/crontab /etc/cron.*/*
sudo cron
sudo service promtail restart 2&>1

if [[ $NETWORK = "master" ]] ; then
sudo bash /home/guild/master-topology.sh
fi

if [[ $NETWORK = "guild_relay" ]] ; then
sudo bash /home/guild/guild-topology.sh
fi


if [[ ! -d "/tmp/mainnet-combo-db" ]] && [[ $NETWORK != "master" ]]  ; then
cp -rf $CNODE_HOME/priv/mainnet-combo-db /tmp/mainnet-combo-db
else 
rm -rf /tmp/mainnet-combo-db
cp -rf $CNODE_HOME/priv/mainnet-combo-db /tmp/mainnet-combo-db
fi

# Create the Node operation keys
#cardano-cli shelley node key-gen-VRF --verification-key-file $CNODE_HOME/priv/vrf.vkey --signing-key-file $CNODE_HOME/priv/vrf.skey
#cardano-cli shelley node key-gen-KES --verification-key-file $CNODE_HOME/priv/kes.vkey --signing-key-file $CNODE_HOME/priv/kes.skey
# TODO: Process to propogate keys in genesis to members
#cardano-cli shelley node issue-op-cert --hot-kes-verification-key-file $CNODE_HOME/priv/kes.vkey --cold-signing-key-file $CNODE_HOME/priv/delegate.skey --operational-certificate-issue-counter $CNODE_HOME/priv/delegate.counter --kes-period 0 --out-file $CNODE_HOME/priv/ops.cert 

# EKG Exposed
#socat -d tcp-listen:12782,reuseaddr,fork tcp:127.0.0.1:12781 

if [[ "$NETWORK" == "relay" ]]; then
  exec cardano-node run \
    --config $CNODE_HOME/priv/files/mainnet-config.json \
    --database-path /tmp/mainnet-combo-db \
    --host-addr 0.0.0.0 \
    --port $CNODE_PORT \
    --socket-path $CNODE_HOME/sockets/node0.socket \
    --topology $CNODE_HOME/priv/files/mainnet-topology.json
elif [[ "$NETWORK" == "master" ]]; then
  exec cardano-node run \
    --config $CNODE_HOME/priv/files/mainnet-config.json \
    --database-path $CNODE_HOME/priv/mainnet-combo-db \
    --host-addr 0.0.0.0 \
    --port $CNODE_PORT \
    --socket-path $CNODE_HOME/sockets/node0.socket \
    --topology $CNODE_HOME/priv/files/mainnet-master.json
elif [[ "$NETWORK" == "pool" ]]; then
  exec cardano-node run \
    --config $CNODE_HOME/priv/files/mainnet-config.json \
    --database-path /tmp/mainnet-combo-db \
    --host-addr 0.0.0.0 \
    --port $CNODE_PORT \
    --socket-path $CNODE_HOME/sockets/node0.socket \
    --shelley-operational-certificate $CNODE_HOME/priv/$POOL/op.cert \
    --shelley-kes-key $CNODE_HOME/priv/$POOL/kes.skey \
    --shelley-vrf-key $CNODE_HOME/priv/$POOL/vrf.skey \
    --topology $CNODE_HOME/priv/files/mainnet-topology.json
elif [[ "$NETWORK" == "guild_relay" ]]; then
  exec cardano-node run \
    --config $CNODE_HOME/priv/files/mainnet-config.json \
    --database-path /tmp/mainnet-combo-db \
    --host-addr 0.0.0.0 \
    --port $CNODE_PORT \
    --socket-path $CNODE_HOME/sockets/node0.socket \
    --topology $CNODE_HOME/priv/files/guild_topology.json
else
  echo "Please set a NETWORK environment variable to one of: relay/master/pool/guild_relay"
  echo "Or mount a /configuration volume containing: configuration.yaml, genesis.json, and topology.json + Pool.cert, Pool.key for active nodes"
fi

/opt/cardano/cnode/scripts/cntoolsBlockCollector.sh &> /tmp/cntoolsBlockCollector.log
