// @review - script works but test cant run because prank and broadcast are incompatible
// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import {Test} from "forge-std/Test.sol";
// import {SetCrosschain, HelperConfig} from "../../../script/interactions/SetCrosschain.s.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {IYieldPeer} from "../../../src/interfaces/IYieldPeer.sol";
// import {TokenPool} from "@chainlink/contracts/src/v0.8/ccip/pools/TokenPool.sol";

// contract SetCrossChainTest is Test {
//     SetCrosschain internal setCrosschain;
//     uint256 internal fujiFork;
//     HelperConfig.NetworkConfig internal networkConfig;
//     address internal localPeer;
//     address internal localPool;

//     function setUp() public {
//         fujiFork = vm.createSelectFork(vm.envString("AVALANCHE_FUJI_RPC_URL"));
//         HelperConfig helperConfig = new HelperConfig();
//         networkConfig = helperConfig.getActiveNetworkConfig();
//         localPeer = networkConfig.peers.localPeer;
//         localPool = networkConfig.peers.localSharePool;
//         // vm.allowCheatcodes(0xC88b1A38eEF111FFBAc4118ac2e6afa82C58773c);
//         // vm.startPrank(0xD208335060493C8f3f5a3626Ac057BD231abF235);

//         setCrosschain = new SetCrosschain();
//         setCrosschain.run();
//     }

//     function test_setCrosschain() public view {
//         assertEq(IYieldPeer(localPeer).getAllowedChain(networkConfig.peers.remoteChainSelectors[0]), true);
//         assertEq(
//             IYieldPeer(localPeer).getAllowedPeer(networkConfig.peers.remoteChainSelectors[0]),
//             networkConfig.peers.remotePeers[0]
//         );
//         assertEq(IYieldPeer(localPeer).getAllowedChain(networkConfig.peers.remoteChainSelectors[1]), true);
//         assertEq(
//             IYieldPeer(localPeer).getAllowedPeer(networkConfig.peers.remoteChainSelectors[1]),
//             networkConfig.peers.remotePeers[1]
//         );
//         assertEq(IYieldPeer(localPeer).getAllowedChain(networkConfig.peers.localChainSelector), true);

//         assertEq(
//             TokenPool(localPool).isRemotePool(
//                 networkConfig.peers.remoteChainSelectors[0], abi.encode(networkConfig.peers.remoteSharePools[0])
//             ),
//             true
//         );
//         assertEq(
//             TokenPool(localPool).isRemotePool(
//                 networkConfig.peers.remoteChainSelectors[1], abi.encode(networkConfig.peers.remoteSharePools[1])
//             ),
//             true
//         );

//         assertEq(
//             TokenPool(localPool).getRemoteToken(networkConfig.peers.remoteChainSelectors[0]),
//             abi.encode(networkConfig.peers.remoteShares[0])
//         );
//         assertEq(
//             TokenPool(localPool).getRemoteToken(networkConfig.peers.remoteChainSelectors[1]),
//             abi.encode(networkConfig.peers.remoteShares[1])
//         );
//     }
// }
