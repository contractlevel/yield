// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IStrategy} from "../interfaces/IStrategy.sol";

/// @title YieldStrategy
/// @author @contractlevel
/// @notice Base contract for yield strategies
abstract contract YieldStrategy is IStrategy {
    /*//////////////////////////////////////////////////////////////
                               ERRORS
    //////////////////////////////////////////////////////////////*/
    error YieldStrategy__OnlyYieldPeer();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    address internal immutable i_yieldPeer;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyYieldPeer() {
        if (msg.sender != i_yieldPeer) revert YieldStrategy__OnlyYieldPeer();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address yieldPeer) {
        i_yieldPeer = yieldPeer;
    }
}
