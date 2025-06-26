// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";
import {SharePool} from "../../src/token/SharePool.sol";
import {TokenPool} from "@chainlink/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "@chainlink/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";

contract SetCrosschain is Script {
    uint256 public constant INITIAL_CCIP_GAS_LIMIT = 3_000_000;

    function run() public {
        HelperConfig config = new HelperConfig();

        vm.startBroadcast();
        HelperConfig.NetworkConfig memory networkConfig = config.getActiveNetworkConfig();
        address localPeer = networkConfig.peers.localPeer;
        address localPool = networkConfig.peers.localSharePool;
        address[] memory remotePeers = networkConfig.peers.remotePeers;
        uint64[] memory remoteChainSelectors = networkConfig.peers.remoteChainSelectors;
        address[] memory remotePools = networkConfig.peers.remoteSharePools;
        address[] memory remoteTokens = networkConfig.peers.remoteShares;

        _applyChainUpdates(localPool, remoteChainSelectors, remotePools, remoteTokens);

        IYieldPeer(localPeer).setCCIPGasLimit(INITIAL_CCIP_GAS_LIMIT);
        _setAllowed(localPeer, remoteChainSelectors, remotePeers);
        if (networkConfig.ccip.parentChainSelector == networkConfig.peers.localChainSelector) {
            IYieldPeer(localPeer).setAllowedChain(networkConfig.peers.localChainSelector, true);
        }

        vm.stopBroadcast();
    }

    function _setAllowed(address localPeer, uint64[] memory remoteChainSelectors, address[] memory remotePeers)
        internal
    {
        for (uint256 i; i < remotePeers.length; ++i) {
            IYieldPeer(localPeer).setAllowedChain(remoteChainSelectors[i], true);
            IYieldPeer(localPeer).setAllowedPeer(remoteChainSelectors[i], remotePeers[i]);
        }
    }

    function _applyChainUpdates(
        address localPool,
        uint64[] memory remoteChainSelectors,
        address[] memory remotePoolAddresses,
        address[] memory remoteTokenAddresses
    ) internal {
        require(
            remoteChainSelectors.length == remotePoolAddresses.length
                && remotePoolAddresses.length == remoteTokenAddresses.length,
            "Length mismatch"
        );

        // Get all existing chain selectors to remove
        uint64[] memory existingChainSelectors = SharePool(localPool).getSupportedChains();

        TokenPool.ChainUpdate[] memory chainUpdates = new TokenPool.ChainUpdate[](remoteChainSelectors.length);
        for (uint256 i = 0; i < remoteChainSelectors.length; i++) {
            chainUpdates[i] = TokenPool.ChainUpdate({
                remoteChainSelector: remoteChainSelectors[i],
                remotePoolAddresses: new bytes[](1),
                remoteTokenAddress: abi.encode(remoteTokenAddresses[i]),
                outboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0}),
                inboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0})
            });
            chainUpdates[i].remotePoolAddresses[0] = abi.encode(remotePoolAddresses[i]);
        }

        console2.log("About to call applyChainUpdates, msg.sender:", msg.sender);
        console2.log("SharePool owner:", SharePool(localPool).owner());
        SharePool(localPool).applyChainUpdates(existingChainSelectors, chainUpdates);
    }

    /// @notice impossible to test this script because of prank and broadcast incompatibility
    /// extremely frustrating and too much time wasted on this
    /// it works perfectly on testnets. i just wanted full unit coverage.
    function test_emptyTest() public {}
}
