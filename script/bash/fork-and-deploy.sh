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

: "${AVALANCHE_MAINNET_RPC_URL:?AVALANCHE_MAINNET_RPC_URL must be set}"
: "${ETH_MAINNET_RPC_URL:?ETH_MAINNET_RPC_URL must be set}"
: "${BASE_MAINNET_RPC_URL:?BASE_MAINNET_RPC_URL must be set}"
: "${DEFAULT_ANVIL_PRIVATE_KEY:?DEFAULT_ANVIL_PRIVATE_KEY must be set}"

############################################################
# 2) Start Avalanche fork on 8545
############################################################

echo "Starting Avalanche fork on port 8545..."
anvil --fork-url "$AVALANCHE_MAINNET_RPC_URL" --port 8545 > anvil-avalanche.log 2>&1 &
ANVIL_AVALANCHE_PID=$!

# Give Anvil a moment to start
sleep 3

############################################################
# 3) Deploy ParentPeer + Rebalancer to Avalanche fork (8545)
############################################################

echo "Deploying ParentPeer and Rebalancer to Avalanche fork (port 8545)..."
forge script script/deploy/DeployParent.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --private-key "$DEFAULT_ANVIL_PRIVATE_KEY" \
  --broadcast \
  --chain-id 43114

############################################################
# 4) Start Ethereum fork on 8546
############################################################

echo "Starting Ethereum fork on port 8546..."
anvil --fork-url "$ETH_MAINNET_RPC_URL" --port 8546 > anvil-ethereum.log 2>&1 &
ANVIL_ETHEREUM_PID=$!

# Give Anvil a moment to start
sleep 3

############################################################
# 5) Deploy ChildPeer to Ethereum fork (8546)
############################################################

echo "Deploying ChildPeer to Ethereum fork (port 8546)..."
forge script script/deploy/DeployChild.s.sol \
  --rpc-url http://127.0.0.1:8546 \
  --private-key "$DEFAULT_ANVIL_PRIVATE_KEY" \
  --broadcast \
  --chain-id 1

############################################################
# 6) Start Base fork on 8547
############################################################

echo "Starting Base fork on port 8547..."
anvil --fork-url "$BASE_MAINNET_RPC_URL" --port 8547 > anvil-base.log 2>&1 &
ANVIL_BASE_PID=$!

# Give Anvil a moment to start
sleep 3

############################################################
# 7) Deploy ChildPeer to Base fork (8547)
############################################################

echo "Deploying ChildPeer to Base fork (port 8547)..."
forge script script/deploy/DeployChild.s.sol \
  --rpc-url http://127.0.0.1:8547 \
  --private-key "$DEFAULT_ANVIL_PRIVATE_KEY" \
  --broadcast \
  --chain-id 8453

############################################################
# 8) Read deployed addresses from Foundry broadcast artifacts
############################################################

AVALANCHE_DEPLOY_FILE="broadcast/DeployParent.s.sol/43114/run-latest.json"
ETHEREUM_DEPLOY_FILE="broadcast/DeployChild.s.sol/1/run-latest.json"
BASE_DEPLOY_FILE="broadcast/DeployChild.s.sol/8453/run-latest.json"

PARENT_PEER_ADDRESS=$(jq -r '.transactions[] | select(.contractName=="ParentPeer") | .contractAddress' "$AVALANCHE_DEPLOY_FILE")
REBALANCER_ADDRESS=$(jq -r '.transactions[] | select(.contractName=="Rebalancer") | .contractAddress' "$AVALANCHE_DEPLOY_FILE")
CHILD_PEER_ETHEREUM_ADDRESS=$(jq -r '.transactions[] | select(.contractName=="ChildPeer") | .contractAddress' "$ETHEREUM_DEPLOY_FILE")
CHILD_PEER_BASE_ADDRESS=$(jq -r '.transactions[] | select(.contractName=="ChildPeer") | .contractAddress' "$BASE_DEPLOY_FILE")

############################################################
# 9) Display deployment summary
############################################################

echo
echo "=========================================="
echo "  DEPLOYMENT SUMMARY"
echo "=========================================="
echo
echo "AVALANCHE (Chain ID: 43114) - Port 8545:"
echo "  ParentPeer:  $PARENT_PEER_ADDRESS"
echo "  Rebalancer:  $REBALANCER_ADDRESS"
echo
echo "ETHEREUM (Chain ID: 1) - Port 8546:"
echo "  ChildPeer:   $CHILD_PEER_ETHEREUM_ADDRESS"
echo
echo "BASE (Chain ID: 8453) - Port 8547:"
echo "  ChildPeer:   $CHILD_PEER_BASE_ADDRESS"
echo
echo "=========================================="
echo
echo "Anvil forks are running:"
echo "  Avalanche: http://127.0.0.1:8545 (PID: $ANVIL_AVALANCHE_PID)"
echo "  Ethereum:  http://127.0.0.1:8546 (PID: $ANVIL_ETHEREUM_PID)"
echo "  Base:      http://127.0.0.1:8547 (PID: $ANVIL_BASE_PID)"
echo
echo "Stop them manually when you are done:"
echo "  kill $ANVIL_AVALANCHE_PID  # Avalanche fork"
echo "  kill $ANVIL_ETHEREUM_PID   # Ethereum fork"
echo "  kill $ANVIL_BASE_PID       # Base fork"