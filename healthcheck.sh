#!/bin/bash

source /opt/cardano/cnode/scripts/env

CCLI=$(which cardano-cli)

FIRST=$($CCLI query tip --shelley-mode --testnet-magic $(grep Magic /opt/cardano/cnode/priv/files/$NETWORK-shelley-genesis.json | awk '{ print $2 }' | cut -d "," -f 1) | jq .blockNo)

sleep 60;

SECOND=$($CCLI query tip --shelley-mode --testnet-magic $(grep Magic /opt/cardano/cnode/priv/files/$NETWORK-shelley-genesis.json | awk '{ print $2 }' | cut -d "," -f 1) | jq .blockNo)


if [[ "$FIRST" -ge "$SECOND" ]]; then
echo "there is a problem";
exit 1
else
echo "we're healthy - $FIRST -> $SECOND"
fi
