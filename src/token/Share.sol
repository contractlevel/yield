// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BurnMintERC677} from "@chainlink/contracts/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";

/// @notice Deployer must grant mint and burn roles to (crosschain) Yield contracts
contract Share is BurnMintERC677 {
    constructor() BurnMintERC677("Yield Share", "SHARE", 18, 0) {}

    // we want to allow the tokens to be moved across chains
}
