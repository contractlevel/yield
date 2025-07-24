// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IYieldPeer} from "./IYieldPeer.sol";

/// @title IStrategyRegistry
/// @author @contractlevel
/// @notice Interface for the StrategyRegistry
interface IStrategyRegistry {
    function getStrategyAdapter(bytes32 protocolId) external view returns (address strategyAdapter);
}
