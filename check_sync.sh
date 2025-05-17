#!/bin/bash

# === Load .env manually if not already set (for local execution) ===
ENV_FILE="/root/holesky-node/.env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

# === Check required environment variables ===
if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "❌ ETHERSCAN_API_KEY is not set. Define it in $ENV_FILE."
    exit 1
fi

if [ -z "$HTTP_GETH_PORT" ]; then
    echo "❌ HTTP_GETH_PORT is not set. Define it in $ENV_FILE."
    exit 1
fi

# === Optional debug flag ===
DEBUG=${DEBUG:-false}

# === Main loop ===
while true; do
    echo "------ $(date) ------"

    # Get local block from node
    local_block_hex=$(curl -s --max-time 10 -X POST -H "Content-Type: application/json" \
      --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
      http://localhost:${HTTP_GETH_PORT} | jq -r '.result')

    # Get remote block from Etherscan
    remote_block_hex=$(curl -s --max-time 10 \
      "https://api-holesky.etherscan.io/api?module=proxy&action=eth_blockNumber&apikey=$ETHERSCAN_API_KEY" | jq -r '.result')

    # Debug output
    if [ "$DEBUG" = "true" ]; then
        echo "DEBUG local_block_hex: $local_block_hex"
        echo "DEBUG remote_block_hex: $remote_block_hex"
    fi

    # Check hex validity
    if [[ ! $local_block_hex =~ ^0x ]] || [[ ! $remote_block_hex =~ ^0x ]]; then
        echo "❌ Invalid response. Check node or Etherscan API."
        sleep 60
        continue
    fi

    # Convert to decimal
    local_block=$((16#${local_block_hex#0x}))
    remote_block=$((16#${remote_block_hex#0x}))

    echo "Local block  : $local_block"
    echo "Network block: $remote_block"

    # Handle syncing or errors
    if [ "$remote_block" -eq 0 ]; then
        echo "❌ Failed to get remote block. Check API key or Etherscan API."
    elif [ "$local_block" -eq 0 ]; then
        echo "⏳ Node is starting or not yet responding to RPC (block = 0)."
    elif [ "$local_block" -ge "$remote_block" ]; then
        echo "✅ Node is fully synced."
    else
        blocks_behind=$((remote_block - local_block))
        sync_percent=$(awk "BEGIN { printf \"%.3f\", 100 * $local_block / $remote_block }")
        echo "⏳ Syncing... $blocks_behind blocks behind ($sync_percent% complete)."
    fi

    echo ""
    sleep 60
done
