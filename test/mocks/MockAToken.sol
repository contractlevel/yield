// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MockAavePool} from "./MockAavePool.sol";

contract MockAToken is ERC20 {
    address internal immutable i_aavePool;

    constructor(address aavePool) ERC20("MockAToken", "aMOCK") {
        i_aavePool = aavePool;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return MockAavePool(i_aavePool).balanceOf(account);
    }
}
