// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title StrategyRegistry
/// @author @contractlevel
/// @notice Registry for strategy adapters
contract StrategyRegistry is Ownable2Step {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice The address of the yield peer on this chain
    address internal immutable i_yieldPeer;

    /// @notice Protocol ID to strategy adapter address
    mapping(bytes32 protocolId => address strategyAdapter) internal s_strategyAdapters;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a strategy adapter is registered
    event StrategyAdapterRegistered(bytes32 indexed protocolId, address indexed strategyAdapter);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param yieldPeer The address of the yield peer on this chain
    constructor(address yieldPeer) Ownable(msg.sender) {
        i_yieldPeer = yieldPeer;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    function registerStrategyAdapter(bytes32 protocolId, address strategyAdapter) external onlyOwner {
        s_strategyAdapters[protocolId] = strategyAdapter;
        emit StrategyAdapterRegistered(protocolId, strategyAdapter);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Get the strategy adapter for a given protocol ID
    /// @param protocolId The protocol ID
    /// @return strategyAdapter The strategy adapter address
    function getStrategyAdapter(bytes32 protocolId) external view returns (address strategyAdapter) {
        strategyAdapter = s_strategyAdapters[protocolId];
    }
}
