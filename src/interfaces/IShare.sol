// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IBurnMintERC20} from "@chainlink/contracts/src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";
import {IERC677} from "@chainlink/contracts/src/v0.8/shared/token/ERC677/IERC677.sol";

interface IShare is IBurnMintERC20, IERC677 {}
