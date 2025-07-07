// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IStrategyAdapter} from "../interfaces/IStrategyAdapter.sol";

/// @title StrategyAdapter
/// @author @contractlevel
/// @notice Base contract for strategy adapters
abstract contract StrategyAdapter is IStrategyAdapter {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error StrategyAdapter__OnlyYieldPeer();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    address internal immutable i_yieldPeer;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyYieldPeer() {
        if (msg.sender != i_yieldPeer) revert StrategyAdapter__OnlyYieldPeer();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address yieldPeer) {
        i_yieldPeer = yieldPeer;
    }
}
