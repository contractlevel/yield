// SPDX-License-Identifier: UNLICENSED
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
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Rebalancer__NotZeroAddress();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    // ERC-7201: keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.Rebalancer")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant REBALANCER_STORAGE_LOCATION =
        0xc3b8b4354c99bf0a184f0d594e91e4d4c7908c52392d7f7c7384b5f321e23c00;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the CRE report is successfully decoded/processed
    event ReportDecoded(uint64 indexed chainSelector, bytes32 indexed protocolId);
    /// @notice Emitted when the ParentPeer contract address is set
    event ParentPeerSet(address indexed parentPeer);

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
        RebalancerStorage storage $ = _getRebalancerStorage(); /// @dev load Rebalancer storage
        IYieldPeer.Strategy memory newStrategy = abi.decode(report, (IYieldPeer.Strategy));

        emit ReportDecoded(newStrategy.chainSelector, newStrategy.protocolId);

        IParentPeer($.s_parentPeer).rebalance(newStrategy);
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

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @return parentPeer The ParentPeer contract address
    function getParentPeer() external view returns (address parentPeer) {
        parentPeer = _getRebalancerStorage().s_parentPeer;
    }

    /// @dev Helper function to expose the Strategy struct for CRE to create Go bindings for encoding
    /// @return currentStrategy The current Strategy (from the Parent peer)
    function getCurrentStrategy() external view returns (IYieldPeer.Strategy memory currentStrategy) {
        address parent = _getRebalancerStorage().s_parentPeer;
        currentStrategy = IParentPeer(parent).getStrategy();
    }
}
