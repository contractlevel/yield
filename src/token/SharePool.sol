// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BurnMintTokenPool, IBurnMintERC20} from "@chainlink/contracts/src/v0.8/ccip/pools/BurnMintTokenPool.sol";

contract SharePool is BurnMintTokenPool {
    /// @param shareToken The SHARE token contract for this chain
    /// @param officialShareTokens Array of addresses of official SHARE token deployments on other chains
    /// @param rmnProxy The Risk Management Network proxy address
    /// @param ccipRouter The CCIP router address
    constructor(IBurnMintERC20 shareToken, address[] memory officialShareTokens, address rmnProxy, address ccipRouter)
        BurnMintTokenPool(shareToken, 18, officialShareTokens, rmnProxy, ccipRouter)
    {}

    // we want to make this IERC677Receiver and onTokenTransfer will handle lockAndBurn to other chains
}
