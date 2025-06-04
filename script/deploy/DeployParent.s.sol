// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {ParentCLF} from "../../src/modules/ParentCLF.sol";
import {Share} from "../../src/token/Share.sol";
import {SharePool} from "../../src/token/SharePool.sol";
import {IFunctionsSubscriptions} from
    "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsSubscriptions.sol";
import {IFunctionsRouter} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsRouter.sol";

contract DeployParent is Script {
    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() public returns (Share, SharePool, ParentCLF, HelperConfig, uint64) {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getActiveNetworkConfig();
        address functionsRouter = networkConfig.clf.functionsRouter;

        vm.startBroadcast();
        // bytes32 allowListId = IFunctionsRouter(functionsRouter).getAllowListId();
        // address termsOfServiceAllowList = IFunctionsRouter(functionsRouter).getContractById(allowListId);
        uint64 clfSubId = IFunctionsSubscriptions(functionsRouter).createSubscription();

        Share share = new Share();
        SharePool sharePool =
            new SharePool(share, new address[](0), networkConfig.ccip.rmnProxy, networkConfig.ccip.ccipRouter);
        ParentCLF parentPeer = new ParentCLF(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            networkConfig.ccip.thisChainSelector,
            networkConfig.tokens.usdc,
            networkConfig.protocols.aavePoolAddressesProvider,
            networkConfig.protocols.comet,
            address(share),
            functionsRouter,
            networkConfig.clf.donId,
            clfSubId
        );
        share.grantMintAndBurnRoles(address(sharePool));
        share.grantMintAndBurnRoles(address(parentPeer));

        vm.stopBroadcast();

        return (share, sharePool, parentPeer, config, clfSubId);
    }
}
