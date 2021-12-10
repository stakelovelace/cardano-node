#!/bin/bash

#set -e
#set -u
#set -o pipefail

trap 'killall -s SIGTERM cardano-node' SIGINT SIGTERM
# "docker run --init" to enable the docker init proxy
# To manually test: docker kill -s SIGTERM container

head -n 8 ~/.scripts/banner.txt

. ~/.bashrc > /dev/null 2>&1

echo "NETWORK: $NETWORK $POOL_NAME $TOPOLOGY";



[[ -z "${CNODE_HOME}" ]] && export CNODE_HOME=/opt/cardano/cnode 
[[ -z "${CNODE_PORT}" ]] && export CNODE_PORT=6000



echo "NODE: $HOSTNAME - Port:$CNODE_PORT - $POOL_NAME";
cardano-node --version;

sudo /etc/init.d/promtail start > /dev/null 2>&1

dbsize=$(du -s ${CNODE_HOME}/db | awk '{print $1}')
bksizedb=$(du -s $CNODE_HOME/priv/$NETWORK-db 2>/dev/null | awk '{print $1}')


# p2p cfg 
p2p () {
cd /opt/cardano/cnode/files
wget https://hydra.iohk.io/build/7654130/download/1/testnet-byron-genesis.json
wget https://hydra.iohk.io/build/7654130/download/1/testnet-shelley-genesis.json
wget https://hydra.iohk.io/build/7654130/download/1/testnet-alonzo-genesis.json
wget https://hydra.iohk.io/build/7654130/download/1/testnet-topology.json
curl https://gist.githubusercontent.com/karknu/b14ae0b965227c36d770bd6e05f95ab5/raw/c07e321d881d902340520cae6952c9822e962452/p2prelay_topology.json -o p2prelay_topology.json
curl https://gist.githubusercontent.com/karknu/752bba3aa2e8281645b93709da44173c/raw/03967ee72bfd70695c2c18e5e8f0a981dc0af86f/p2pbp_topology.json -o p2pbp_topology.json
}

poolreaysetup () {
sed -i 's/\"1.1.1.1\", \"port\": 3001/\"92.204.53.48\", \"port\": 5401/g'  /opt/cardano/cnode/files/p2pbp_topology.json
sed -i 's/\"1.1.1.2\", \"port\": 3001/\"92.204.53.48\", \"port\": 5400/g'  /opt/cardano/cnode/files/p2pbp_topology.json
}

# Customisation 
customise () {
find /opt/cardano/cnode -name "*config*.json" -print0 | xargs -0 sed -i 's/127.0.0.1/0.0.0.0/g' > /dev/null 2>&1 
find /opt/cardano/cnode/files -name "cntools.config" -print0 | xargs -0 sed -i 's/ENABLE_CHATTR=true/ENABLE_CHATTR=false/g' > /dev/null 2>&1
find /opt/cardano/cnode/files -name "*config*.json" -print0 | xargs -0 sed -i 's/\"hasEKG\": 12788,/\"hasEKG\": [\n    \"0.0.0.0\",\n    12788\n],/g' > /dev/null 2>&1
return 0
}

if [  ${POOL_NAME} ]; then  poolreaysetup; fi
export UPDATE_CHECK='N'

if [[ "$NETWORK" == "mainnet" ]]; then
  customise \
  && exec $CNODE_HOME/scripts/cnode.sh
elif [[ "$NETWORK" == "testnet" ]]; then
  p2p \
  && customise \
  && exec $CNODE_HOME/scripts/cnode.sh
elif [[ "$NETWORK" == "guild" ]]; then
  $CNODE_HOME/scripts/prereqs.sh -n guild -t cnode -s -f -w > /dev/null 2>&1 \
  && customise \
  && exec $CNODE_HOME/scripts/cnode.sh
else
  echo "or just set POOL_NAME environment variable (for default path)."
fi
