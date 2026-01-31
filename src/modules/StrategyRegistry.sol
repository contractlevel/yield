// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IStrategyRegistry} from "../interfaces/IStrategyRegistry.sol";

/// @title StrategyRegistry
/// @author @contractlevel
/// @notice Registry for strategy adapters and stablecoins
contract StrategyRegistry is IStrategyRegistry, Ownable2Step {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice Protocol ID to strategy adapter address
    /// @notice Protocol IDs should be generated using keccak256 with consistent formatting:
    /// @dev Examples:
    /// @dev bytes32 aaveV3Id = keccak256("aave-v3");
    /// @dev bytes32 compoundV3Id = keccak256("compound-v3");
    /// @notice The string hashed is the "project" from the DefiLlama yields pools API
    mapping(bytes32 protocolId => address strategyAdapter) internal s_strategyAdapters;

    /// @notice Stablecoin ID to stablecoin address
    /// @notice Stablecoin IDs should be generated using keccak256 with consistent formatting:
    /// @dev Examples:
    /// @dev bytes32 usdcId = keccak256("USDC");
    /// @dev bytes32 usdtId = keccak256("USDT");
    /// @dev bytes32 ghoId = keccak256("GHO");
    mapping(bytes32 stablecoinId => address stablecoin) internal s_stablecoins;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a strategy adapter is registered
    event StrategyAdapterSet(bytes32 indexed protocolId, address indexed strategyAdapter);
    /// @notice Emitted when a stablecoin is registered
    event StablecoinSet(bytes32 indexed stablecoinId, address indexed stablecoin);

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
    /// @notice This does not explicitly sync with ParentPeer::s_supportedProtocols at the contract level because
    /// this is also deployed on child chains and this contract is primarily inteded as a registry for adapters.
    function setStrategyAdapter(bytes32 protocolId, address strategyAdapter) external onlyOwner {
        s_strategyAdapters[protocolId] = strategyAdapter;
        emit StrategyAdapterSet(protocolId, strategyAdapter);
    }

    /// @notice Setter for registering and deregistering a stablecoin
    /// @dev Revert if msg.sender is not the owner
    /// @param stablecoinId The stablecoin ID should be generated using keccak256 with consistent formatting:
    /// @dev Examples:
    /// @dev bytes32 usdcId = keccak256("USDC");
    /// @dev bytes32 usdtId = keccak256("USDT");
    /// @dev bytes32 ghoId = keccak256("GHO");
    /// @param stablecoin The stablecoin address (use address(0) to deregister)
    function setStablecoin(bytes32 stablecoinId, address stablecoin) external onlyOwner {
        s_stablecoins[stablecoinId] = stablecoin;
        emit StablecoinSet(stablecoinId, stablecoin);
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

    /// @notice Get the stablecoin address for a given stablecoin ID
    /// @param stablecoinId The stablecoin ID
    /// @return stablecoin The stablecoin address
    function getStablecoin(bytes32 stablecoinId) external view returns (address stablecoin) {
        stablecoin = s_stablecoins[stablecoinId];
    }

    /// @notice Check if a stablecoin is supported
    /// @param stablecoinId The stablecoin ID
    /// @return isSupported Whether the stablecoin is supported on this chain
    function isStablecoinSupported(bytes32 stablecoinId) external view returns (bool isSupported) {
        isSupported = s_stablecoins[stablecoinId] != address(0);
    }
}
