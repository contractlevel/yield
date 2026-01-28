// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {
    Ownable2StepUpgradeable,
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IStrategyRegistry} from "../interfaces/IStrategyRegistry.sol";

/// @title StrategyRegistry
/// @author @contractlevel
/// @notice Registry for strategy adapters
contract StrategyRegistry is Initializable, UUPSUpgradeable, IStrategyRegistry, Ownable2StepUpgradeable {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    /// @custom:storage-location erc7201:yieldcoin.storage.StrategyRegistry
    struct StrategyRegistryStorage {
        /// @notice Protocol ID to strategy adapter address
        /// @notice Protocol IDs should be generated using keccak256 with consistent formatting:
        /// @dev Examples:
        /// @dev bytes32 aaveV3Id = keccak256("aave-v3");
        /// @dev bytes32 compoundV3Id = keccak256("compound-v3");
        /// @notice The string hashed for the protocol ID should match what is hashed in the Chainlink Functions source code - see functions/src.js
        /// The string hashed is the "project" from the DefiLlama yields pools API
        mapping(bytes32 protocolId => address strategyAdapter) s_strategyAdapters;
    }

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    // keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.StrategyRegistry")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant STRATEGY_REGISTRY_STORAGE_LOCATION =
        0xff4f32e19ccce71bf80077033cba16a319c7bee7ac2089685e40116337a8fe00; // @review double check the hash

    /// @notice Version of the contract logic
    string public constant VERSION = "1.0.0";

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a strategy adapter is registered
    event StrategyAdapterSet(bytes32 indexed protocolId, address indexed strategyAdapter);

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR / INIT
    //////////////////////////////////////////////////////////////*/
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init(msg.sender);
    }

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
        StrategyRegistryStorage storage $ = _getStrategyRegistryStorage(); // load StrategyRegistry storage
        $.s_strategyAdapters[protocolId] = strategyAdapter;
        emit StrategyAdapterSet(protocolId, strategyAdapter);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Authorizes an upgrade to a new implementation
    /// @param newImplementation The address of the new implementation
    /// @dev Revert if msg.sender does not have UPGRADER_ROLE
    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /*//////////////////////////////////////////////////////////////
                         PRIVATE PURE / STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @notice Get the StrategyRegistry storage
    /// @return $ The StrategyRegistry storage
    function _getStrategyRegistryStorage() private pure returns (StrategyRegistryStorage storage $) {
        assembly {
            $.slot := STRATEGY_REGISTRY_STORAGE_LOCATION
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Get the strategy adapter for a given protocol ID
    /// @param protocolId The protocol ID
    /// @return strategyAdapter The strategy adapter address
    function getStrategyAdapter(bytes32 protocolId) external view returns (address strategyAdapter) {
        StrategyRegistryStorage storage $ = _getStrategyRegistryStorage(); // load StrategyRegistry storage
        strategyAdapter = $.s_strategyAdapters[protocolId];
    }

    /// @notice Get the version of the contract logic
    /// @return VERSION The version of the contract logic
    function getVersion() external pure returns (string memory) {
        return VERSION;
    }
}
