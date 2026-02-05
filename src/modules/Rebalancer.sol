// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {CREReceiver} from "./CREReceiver.sol";
import {IParentPeer, IYieldPeer} from "../interfaces/IParentPeer.sol";
import {IStrategyRegistry} from "../interfaces/IStrategyRegistry.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title Rebalancer
/// @author George Gorzhiyev - Judge Finance
/// @notice A minimal version of the previous YieldCoin Rebalancer.
/// @notice Decodes verified CRE report and sets new Strategy on Parent peer.
contract Rebalancer is Initializable, UUPSUpgradeable, CREReceiver {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    /// @custom:storage-location erc7201:yieldcoin.storage.Rebalancer
    struct RebalancerStorage {
        /// @dev ParentPeer contract address
        address s_parentPeer;
        /// @dev Strategy registry
        address s_strategyRegistry;
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Rebalancer__NotZeroAddress();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    // keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.Rebalancer")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant REBALANCER_STORAGE_LOCATION =
        0xc3b8b4354c99bf0a184f0d594e91e4d4c7908c52392d7f7c7384b5f321e23c00;

    /// @notice Version of the contract logic
    string public constant VERSION = "1.0.0";

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a CRE report returns an invalid chain selector
    event InvalidChainSelectorInReport(uint64 indexed chainSelector);
    /// @notice Emitted when a CRE report returns an invalid protocol ID
    event InvalidProtocolIdInReport(bytes32 indexed protocolId);
    /// @notice Emitted when the CRE report is successfully decoded/processed
    event ReportDecoded(uint64 indexed chainSelector, bytes32 indexed protocolId);
    /// @notice Emitted when the ParentPeer contract address is set
    event ParentPeerSet(address indexed parentPeer);
    /// @notice Emitted when the strategy registry is set
    event StrategyRegistrySet(address indexed strategyRegistry);

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR / INIT
    //////////////////////////////////////////////////////////////*/
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract
    function initialize() external initializer {
        __CREReceiver_init(msg.sender); // Sets owner
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc CREReceiver
    /// @notice After security checks, gets CRE report from CREReceiver for consumption
    /// @notice This implementation of _onReport expects to receive new strategy, checks strategy, and then forwards to parent to update
    /// @param report The CRE report
    function _onReport(bytes calldata report) internal override {
        IYieldPeer.Strategy memory newStrategy = abi.decode(report, (IYieldPeer.Strategy));
        uint64 chainSelector = newStrategy.chainSelector;
        bytes32 protocolId = newStrategy.protocolId;

        RebalancerStorage storage $ = _getRebalancerStorage(); /// @dev load Rebalancer storage

        // @review Would it be better to revert on this one?
        if (!IParentPeer($.s_parentPeer).getAllowedChain(chainSelector)) {
            emit InvalidChainSelectorInReport(chainSelector);
            return;
        }

        // Verify protocol Id from report
        if (IStrategyRegistry($.s_strategyRegistry).getStrategyAdapter(protocolId) == address(0)) {
            emit InvalidProtocolIdInReport(protocolId);
            return;
        }

        emit ReportDecoded(newStrategy.chainSelector, newStrategy.protocolId);

        IParentPeer($.s_parentPeer).setStrategy(chainSelector, protocolId);
    }

    /// @notice Authorizes an upgrade to a new implementation
    /// @param newImplementation The address of the new implementation
    /// @dev Revert if msg.sender is not owner
    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /*//////////////////////////////////////////////////////////////
                         PRIVATE PURE / STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @notice Get the Rebalancer storage
    /// @return $ The Rebalancer storage
    function _getRebalancerStorage() private pure returns (RebalancerStorage storage $) {
        assembly {
            $.slot := REBALANCER_STORAGE_LOCATION
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the ParentPeer contract address
    /// @param parentPeer The address of the ParentPeer contract
    /// @dev Revert if the caller is not the owner
    /// @dev Revert if setting to 0 address
    function setParentPeer(address parentPeer) external onlyOwner {
        if (parentPeer == address(0)) revert Rebalancer__NotZeroAddress();
        _getRebalancerStorage().s_parentPeer = parentPeer;
        emit ParentPeerSet(parentPeer);
    }

    /// @notice Sets the strategy registry
    /// @param strategyRegistry The address of the strategy registry
    /// @dev Revert if the caller is not the owner
    /// @dev Revert if setting to 0 address
    function setStrategyRegistry(address strategyRegistry) external onlyOwner {
        if (strategyRegistry == address(0)) revert Rebalancer__NotZeroAddress();
        _getRebalancerStorage().s_strategyRegistry = strategyRegistry;
        emit StrategyRegistrySet(strategyRegistry);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @return parentPeer The ParentPeer contract address
    function getParentPeer() external view returns (address parentPeer) {
        parentPeer = _getRebalancerStorage().s_parentPeer;
    }

    /// @return strategyRegistry The strategy registry address
    function getStrategyRegistry() external view returns (address strategyRegistry) {
        strategyRegistry = _getRebalancerStorage().s_strategyRegistry;
    }

    /// @dev Helper function to expose the Strategy struct for CRE to create Go bindings for encoding
    /// @return currentStrategy The current Strategy (from the Parent peer)
    function getCurrentStrategy() external view returns (IYieldPeer.Strategy memory currentStrategy) {
        address parent = _getRebalancerStorage().s_parentPeer;
        currentStrategy = IParentPeer(parent).getStrategy();
    }

    /// @return VERSION The version of the contract logic
    function getVersion() external pure returns (string memory) {
        return VERSION;
    }
}
