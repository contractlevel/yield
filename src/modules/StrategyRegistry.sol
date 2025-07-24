// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IStrategyRegistry} from "../interfaces/IStrategyRegistry.sol";

/// @title StrategyRegistry
/// @author @contractlevel
/// @notice Registry for strategy adapters
contract StrategyRegistry is IStrategyRegistry, Ownable2Step {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice Protocol ID to strategy adapter address
    /// @notice Protocol IDs should be generated using keccak256 with consistent formatting:
    /// @dev Examples:
    /// @dev bytes32 aaveV3Id = keccak256("aave-v3");
    /// @dev bytes32 compoundV3Id = keccak256("compound-v3");
    /// @notice The string hashed for the protocol ID should match what is hashed in the Chainlink Functions source code - see functions/src.js
    mapping(bytes32 protocolId => address strategyAdapter) internal s_strategyAdapters;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a strategy adapter is registered
    event StrategyAdapterSet(bytes32 indexed protocolId, address indexed strategyAdapter);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Setter for registering and deregistering a strategy adapter
    /// @dev Revert if msg.sender is not the owner
    /// @param protocolId The protocol ID should be generated using keccak256 with consistent formatting:
    /// @dev Examples:
    /// @dev bytes32 aaveV3Id = keccak256("aave-v3");
    /// @dev bytes32 compoundV3Id = keccak256("compound-v3");
    /// @notice The string hashed for the protocol ID should match what is hashed in the Chainlink Functions source code - see functions/src.js
    /// @param strategyAdapter The strategy adapter address
    function setStrategyAdapter(bytes32 protocolId, address strategyAdapter) external onlyOwner {
        s_strategyAdapters[protocolId] = strategyAdapter;
        emit StrategyAdapterSet(protocolId, strategyAdapter);
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
