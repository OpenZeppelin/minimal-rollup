#!/bin/bash

# CONFIG 
# Anvil account [0]
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
CONTRACT_NAME="SignalService"
ROLLUP_OPERATOR="0xCf03Dd0a894Ef79CB5b601A43C4b25E3Ae4c67eD"
SIGNAL='0xe321d900f3fd366734e2d071e30949ded20c27fd638f1a059390091c643b62c5'
SLOT=0xdf4711e2bacf3407f4dd99aff960326754085972cf995e30e8ea995c9080ef00
BLOCK_TIME=1

# START ANVIL
anvil --quiet --block-time ${BLOCK_TIME} &
ANVIL_PID=$!
sleep 1

# COMPILE
forge build -q

# DEPLOY
DEPLOY_CMD="forge create --broadcast src/protocol/${CONTRACT_NAME}.sol:${CONTRACT_NAME} --private-key $PRIVATE_KEY --constructor-args $ROLLUP_OPERATOR | grep "
ADDRESS=$($DEPLOY_CMD | grep "Deployed to:" | awk '{print $3}')
echo "📦 Contract deployed to: $ADDRESS"

# SEND SIGNAL   
cast send ${ADDRESS} 'sendSignal(bytes32)' ${SIGNAL} \
   \
  --private-key ${PRIVATE_KEY} --quiet

# GET STATE ROOT
RESPONSE=$(
    curl -s http://localhost:8545 -X POST -H "Content-Type: application/json" \
        --data '{"method":"eth_getBlockByNumber","params":["latest",false],"id":1,"jsonrpc":"2.0"}'
    )

STATE_ROOT=$(echo "$RESPONSE" | jq -r '.result.stateRoot')
echo "🌳 State root: $STATE_ROOT"

# GET PROOF
cast proof ${ADDRESS}  ${SLOT} | jq '{storageHash, accountProof, storageProof}'


# KILL ANVIL
kill $ANVIL_PID
