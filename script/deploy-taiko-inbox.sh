#!/bin/bash
set -e

# Script to deploy TaikoInbox contract using Foundry

# Default values
DEFAULT_RPC_URL="http://localhost:8545"
DEFAULT_PRIVATE_KEY=""
DEFAULT_MAX_ANCHOR_BLOCK_ID_OFFSET=256
DEFAULT_INCLUSION_DELAY=3600  # 1 hour in seconds

# Parse command line arguments
RPC_URL=${RPC_URL:-$DEFAULT_RPC_URL}
PRIVATE_KEY=${PRIVATE_KEY:-$DEFAULT_PRIVATE_KEY}
MAX_ANCHOR_BLOCK_ID_OFFSET=${MAX_ANCHOR_BLOCK_ID_OFFSET:-$DEFAULT_MAX_ANCHOR_BLOCK_ID_OFFSET}
INCLUSION_DELAY=${INCLUSION_DELAY:-$DEFAULT_INCLUSION_DELAY}

# Required addresses - no defaults
if [ -z "$BLOB_REF_REGISTRY_ADDRESS" ]; then
    echo "Error: BLOB_REF_REGISTRY_ADDRESS environment variable is required"
    exit 1
fi

if [ -z "$PROPOSER_FEES_ADDRESS" ]; then
    echo "Error: PROPOSER_FEES_ADDRESS environment variable is required"
    exit 1
fi

# Optional: LOOKAHEAD_ADDRESS (defaults to address(0) in the script)
LOOKAHEAD_ADDRESS=${LOOKAHEAD_ADDRESS:-"0x0000000000000000000000000000000000000000"}

echo "Deploying TaikoInbox contract with the following parameters:"
echo "RPC URL: $RPC_URL"
echo "Lookahead Address: $LOOKAHEAD_ADDRESS"
echo "Blob Ref Registry Address: $BLOB_REF_REGISTRY_ADDRESS"
echo "Max Anchor Block ID Offset: $MAX_ANCHOR_BLOCK_ID_OFFSET"
echo "Proposer Fees Address: $PROPOSER_FEES_ADDRESS"
echo "Inclusion Delay: $INCLUSION_DELAY"

# Export environment variables for the Foundry script
export LOOKAHEAD_ADDRESS
export BLOB_REF_REGISTRY_ADDRESS
export MAX_ANCHOR_BLOCK_ID_OFFSET
export PROPOSER_FEES_ADDRESS
export INCLUSION_DELAY

# Run the Foundry script to deploy the TaikoInbox contract
forge script script/DeployTaikoInbox.s.sol:DeployTaikoInbox \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast \
    --verify \
    -vvv

echo "Deployment completed!"

