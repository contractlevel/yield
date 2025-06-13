// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BurnMintTokenPool, IBurnMintERC20} from "@chainlink/contracts/src/v0.8/ccip/pools/BurnMintTokenPool.sol";

contract SharePool is BurnMintTokenPool {
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param shareToken The SHARE token contract for this chain
    /// @param rmnProxy The Risk Management Network proxy address
    /// @param ccipRouter The CCIP router address
    constructor(address shareToken, address rmnProxy, address ccipRouter)
        BurnMintTokenPool(IBurnMintERC20(shareToken), 18, new address[](0), rmnProxy, ccipRouter)
    {}
}
