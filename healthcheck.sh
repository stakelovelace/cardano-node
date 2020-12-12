#!/bin/bash

source /opt/cardano/cnode/scripts/env
CCLI=$(which cardano-cli)

FIRST=$($CCLI query tip --shelley-mode --mainnet | jq .blockNo)

sleep 60;

SECOND=$($CCLI query tip --shelley-mode --mainnet | jq .blockNo)


if [[ "$FIRST" -ge "$SECOND" ]]; then
echo "there is a problem";
exit 1
else
echo "we're healthy - $FIRST -> $SECOND"
fi
