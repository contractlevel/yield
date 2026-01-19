# bash ./script/bash/fork-and-deploy.sh
# ps aux | grep anvil
# kill <PID>
# bash ./script/bash/kill.sh

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
: "${ARBITRUM_MAINNET_RPC_URL:?ARBITRUM_MAINNET_RPC_URL must be set}"
: "${OPTIMISM_MAINNET_RPC_URL:?OPTIMISM_MAINNET_RPC_URL must be set}"
: "${POLYGON_MAINNET_RPC_URL:?POLYGON_MAINNET_RPC_URL must be set}"
: "${DEFAULT_ANVIL_PRIVATE_KEY:?DEFAULT_ANVIL_PRIVATE_KEY must be set}"

############################################################
# 2) Helper function to wait for Anvil to be ready
############################################################

wait_for_anvil() {
    local port=$1
    local max_attempts=30
    local attempt=0
    
    echo "Waiting for Anvil on port $port to be ready..."
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -X POST "http://127.0.0.1:$port" \
            -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            > /dev/null 2>&1; then
            echo "Anvil on port $port is ready!"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 1
    done
    
    echo "ERROR: Anvil on port $port failed to become ready after $max_attempts seconds"
    return 1
}

############################################################
# 3) Create logs directory
############################################################

mkdir -p script/bash/logs

############################################################
# 4) Start Avalanche fork on 8545
############################################################

echo "Starting Avalanche fork on port 8545..."
anvil --fork-url "$AVALANCHE_MAINNET_RPC_URL" --port 8545 > script/bash/logs/anvil-avalanche.log 2>&1 &
ANVIL_AVALANCHE_PID=$!

# Wait for Anvil to be ready
wait_for_anvil 8545

############################################################
# 5) Deploy ParentPeer + Rebalancer to Avalanche fork (8545)
############################################################

echo "Deploying ParentPeer and Rebalancer to Avalanche fork (port 8545)..."
forge script script/deploy/DeployParent.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --private-key "$DEFAULT_ANVIL_PRIVATE_KEY" \
  --broadcast \
  --chain-id 43114

############################################################
# 6) Start Ethereum fork on 8546
############################################################

echo "Starting Ethereum fork on port 8546..."
anvil --fork-url "$ETH_MAINNET_RPC_URL" --port 8546 > script/bash/logs/anvil-ethereum.log 2>&1 &
ANVIL_ETHEREUM_PID=$!

# Wait for Anvil to be ready
wait_for_anvil 8546

############################################################
# 7) Deploy ChildPeer to Ethereum fork (8546)
############################################################

echo "Deploying ChildPeer to Ethereum fork (port 8546)..."
forge script script/deploy/DeployChild.s.sol \
  --rpc-url http://127.0.0.1:8546 \
  --private-key "$DEFAULT_ANVIL_PRIVATE_KEY" \
  --broadcast \
  --chain-id 1

############################################################
# 8) Start Base fork on 8547
############################################################

echo "Starting Base fork on port 8547..."
anvil --fork-url "$BASE_MAINNET_RPC_URL" --port 8547 > script/bash/logs/anvil-base.log 2>&1 &
ANVIL_BASE_PID=$!

# Wait for Anvil to be ready
wait_for_anvil 8547

############################################################
# 9) Deploy ChildPeer to Base fork (8547)
############################################################

echo "Deploying ChildPeer to Base fork (port 8547)..."
forge script script/deploy/DeployChild.s.sol \
  --rpc-url http://127.0.0.1:8547 \
  --private-key "$DEFAULT_ANVIL_PRIVATE_KEY" \
  --broadcast \
  --chain-id 8453

############################################################
# 10) Start Arbitrum fork on 8548
############################################################

echo "Starting Arbitrum fork on port 8548..."
anvil --fork-url "$ARBITRUM_MAINNET_RPC_URL" --port 8548 > script/bash/logs/anvil-arbitrum.log 2>&1 &
ANVIL_ARBITRUM_PID=$!

# Wait for Anvil to be ready
wait_for_anvil 8548

############################################################
# 11) Deploy ChildPeer to Arbitrum fork (8548)
############################################################

echo "Deploying ChildPeer to Arbitrum fork (port 8548)..."
forge script script/deploy/DeployChild.s.sol \
  --rpc-url http://127.0.0.1:8548 \
  --private-key "$DEFAULT_ANVIL_PRIVATE_KEY" \
  --broadcast \
  --chain-id 42161

############################################################
# 12) Start Optimism fork on 8549
############################################################

echo "Starting Optimism fork on port 8549..."
anvil --fork-url "$OPTIMISM_MAINNET_RPC_URL" --port 8549 > script/bash/logs/anvil-optimism.log 2>&1 &
ANVIL_OPTIMISM_PID=$!

# Wait for Anvil to be ready
wait_for_anvil 8549

############################################################
# 13) Deploy ChildPeer to Optimism fork (8549)
############################################################

echo "Deploying ChildPeer to Optimism fork (port 8549)..."
forge script script/deploy/DeployChild.s.sol \
  --rpc-url http://127.0.0.1:8549 \
  --private-key "$DEFAULT_ANVIL_PRIVATE_KEY" \
  --broadcast \
  --chain-id 10

############################################################
# 14) Start Polygon fork on 8550
############################################################

echo "Starting Polygon fork on port 8550..."
anvil --fork-url "$POLYGON_MAINNET_RPC_URL" --port 8550 > script/bash/logs/anvil-polygon.log 2>&1 &
ANVIL_POLYGON_PID=$!

# Wait for Anvil to be ready
wait_for_anvil 8550

############################################################
# 15) Deploy ChildPeer to Polygon fork (8550)
############################################################

echo "Deploying ChildPeer to Polygon fork (port 8550)..."
forge script script/deploy/DeployChild.s.sol \
  --rpc-url http://127.0.0.1:8550 \
  --private-key "$DEFAULT_ANVIL_PRIVATE_KEY" \
  --broadcast \
  --chain-id 137

############################################################
# 16) Read deployed addresses from Foundry broadcast artifacts
############################################################

AVALANCHE_DEPLOY_FILE="broadcast/DeployParent.s.sol/43114/run-latest.json"
ETHEREUM_DEPLOY_FILE="broadcast/DeployChild.s.sol/1/run-latest.json"
BASE_DEPLOY_FILE="broadcast/DeployChild.s.sol/8453/run-latest.json"
ARBITRUM_DEPLOY_FILE="broadcast/DeployChild.s.sol/42161/run-latest.json"
OPTIMISM_DEPLOY_FILE="broadcast/DeployChild.s.sol/10/run-latest.json"
POLYGON_DEPLOY_FILE="broadcast/DeployChild.s.sol/137/run-latest.json"

PARENT_PEER_ADDRESS=$(jq -r '.transactions[] | select(.contractName=="ParentPeer") | .contractAddress' "$AVALANCHE_DEPLOY_FILE")
REBALANCER_ADDRESS=$(jq -r '.transactions[] | select(.contractName=="Rebalancer") | .contractAddress' "$AVALANCHE_DEPLOY_FILE")
CHILD_PEER_ETHEREUM_ADDRESS=$(jq -r '.transactions[] | select(.contractName=="ChildPeer") | .contractAddress' "$ETHEREUM_DEPLOY_FILE")
CHILD_PEER_BASE_ADDRESS=$(jq -r '.transactions[] | select(.contractName=="ChildPeer") | .contractAddress' "$BASE_DEPLOY_FILE")
CHILD_PEER_ARBITRUM_ADDRESS=$(jq -r '.transactions[] | select(.contractName=="ChildPeer") | .contractAddress' "$ARBITRUM_DEPLOY_FILE")
CHILD_PEER_OPTIMISM_ADDRESS=$(jq -r '.transactions[] | select(.contractName=="ChildPeer") | .contractAddress' "$OPTIMISM_DEPLOY_FILE")
CHILD_PEER_POLYGON_ADDRESS=$(jq -r '.transactions[] | select(.contractName=="ChildPeer") | .contractAddress' "$POLYGON_DEPLOY_FILE")

############################################################
# 17) Display deployment summary
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
echo "ARBITRUM (Chain ID: 42161) - Port 8548:"
echo "  ChildPeer:   $CHILD_PEER_ARBITRUM_ADDRESS"
echo
echo "OPTIMISM (Chain ID: 10) - Port 8549:"
echo "  ChildPeer:   $CHILD_PEER_OPTIMISM_ADDRESS"
echo
echo "POLYGON (Chain ID: 137) - Port 8550:"
echo "  ChildPeer:   $CHILD_PEER_POLYGON_ADDRESS"
echo
echo "=========================================="
echo
echo "Anvil forks are running:"
echo "  Avalanche: http://127.0.0.1:8545 (PID: $ANVIL_AVALANCHE_PID)"
echo "  Ethereum:  http://127.0.0.1:8546 (PID: $ANVIL_ETHEREUM_PID)"
echo "  Base:      http://127.0.0.1:8547 (PID: $ANVIL_BASE_PID)"
echo "  Arbitrum:  http://127.0.0.1:8548 (PID: $ANVIL_ARBITRUM_PID)"
echo "  Optimism:  http://127.0.0.1:8549 (PID: $ANVIL_OPTIMISM_PID)"
echo "  Polygon:   http://127.0.0.1:8550 (PID: $ANVIL_POLYGON_PID)"
echo
echo "Stop them manually when you are done:"
echo "  kill $ANVIL_AVALANCHE_PID"
echo "  kill $ANVIL_ETHEREUM_PID"
echo "  kill $ANVIL_BASE_PID"
echo "  kill $ANVIL_ARBITRUM_PID"
echo "  kill $ANVIL_OPTIMISM_PID"
echo "  kill $ANVIL_POLYGON_PID"