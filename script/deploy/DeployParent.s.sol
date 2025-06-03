// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {ParentPeer} from "../../src/peers/ParentPeer.sol";
import {Share} from "../../src/token/Share.sol";
import {SharePool} from "../../src/token/SharePool.sol";

contract DeployParent is Script {
    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() public returns (Share, SharePool, ParentPeer, HelperConfig) {
        HelperConfig config = new HelperConfig();
        (
            address ccipRouter,
            address link,
            uint64 thisChainSelector,
            address usdc,
            address aavePoolAddressesProvider,
            address comet,
            , // address share
            uint64 parentChainSelector,
            address rmnProxy,
            ,
        ) = config.activeNetworkConfig();

        vm.startBroadcast();
        Share share = new Share();
        SharePool sharePool = new SharePool(share, new address[](0), rmnProxy, ccipRouter);
        ParentPeer parentPeer =
            new ParentPeer(ccipRouter, link, thisChainSelector, usdc, aavePoolAddressesProvider, comet, address(share));
        share.grantMintAndBurnRoles(address(sharePool));
        share.grantMintAndBurnRoles(address(parentPeer));

        vm.stopBroadcast();

        return (share, sharePool, parentPeer, config);
    }
}
