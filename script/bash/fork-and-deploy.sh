# ./script/bash/fork-and-deploy.sh
# ps aux | grep anvil
# kill <PID>

# cast code 0x51cceaa25e6700e8c733d3130dbcab75e357b0b2 --rpc-url http://127.0.0.1:8545
# cast call 0x51cceaa25e6700e8c733d3130dbcab75e357b0b2 "getStrategy()" --rpc-url http://127.0.0.1:8545



#!/usr/bin/env bash
set -euo pipefail

############################################################
# 1) Load env and check required variables
############################################################

# Optional: load .env into the environment
if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . .env
  set +a
fi

: "${ETH_MAINNET_RPC_URL:?ETH_MAINNET_RPC_URL must be set}"
: "${DEFAULT_ANVIL_PRIVATE_KEY:?DEFAULT_ANVIL_PRIVATE_KEY must be set}"

############################################################
# 2) Start mainnet fork on 8545 (kept running)
############################################################

anvil --fork-url "$ETH_MAINNET_RPC_URL" --port 8545 > anvil.log 2>&1 &
ANVIL_PID=$!

# Give Anvil a moment to start
sleep 3

############################################################
# 3) Deploy ParentPeer + Rebalancer to the fork
############################################################

forge script script/deploy/DeployParent.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --private-key "$DEFAULT_ANVIL_PRIVATE_KEY" \
  --broadcast \
  --chain-id 1

############################################################
# 4) Mine 32 blocks so the deployment becomes finalized
############################################################

echo "Mining 32 blocks on Anvil to advance finality..."
cast rpc anvil_mine 0x20 --rpc-url http://127.0.0.1:8545 >/dev/null
echo "Mined 32 blocks."

############################################################
# 5) Read deployed addresses from Foundry broadcast artifacts
############################################################

DEPLOY_FILE="broadcast/DeployParent.s.sol/1/run-latest.json"

PARENT_PEER_ADDRESS=$(jq -r '.transactions[] | select(.contractName=="ParentPeer") | .contractAddress' "$DEPLOY_FILE")
REBALANCER_ADDRESS=$(jq -r '.transactions[] | select(.contractName=="Rebalancer") | .contractAddress' "$DEPLOY_FILE")

echo "ParentPeer deployed at:  $PARENT_PEER_ADDRESS"
echo "Rebalancer deployed at:  $REBALANCER_ADDRESS"
echo
echo "Anvil mainnet fork is running on http://127.0.0.1:8545 (PID: $ANVIL_PID)"
echo "Stop it manually when you are done (e.g.: kill $ANVIL_PID)"