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
                                 VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev ParentPeer contract address
    address internal immutable i_parentPeer;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the CRE report is successfully decoded/processed
    event ReportDecoded(uint64 indexed chainSelector, bytes32 indexed protocolId);

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR / INIT
    //////////////////////////////////////////////////////////////*/
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address parentPeer) {
        i_parentPeer = parentPeer;
        _disableInitializers();
    }

    /// @notice Initializes the contract
    function initialize() external initializer {
        __CREReceiver_init();
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

        emit ReportDecoded(newStrategy.chainSelector, newStrategy.protocolId);

        IParentPeer(i_parentPeer).rebalance(newStrategy);
    }

    /// @notice Authorizes an upgrade to a new implementation
    /// @param newImplementation The address of the new implementation
    /// @dev Revert if msg.sender is not owner
    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @return parentPeer The ParentPeer contract address
    function getParentPeer() external view returns (address parentPeer) {
        parentPeer = i_parentPeer;
    }

    /// @dev Helper function to expose the Strategy struct for CRE to create Go bindings for encoding
    /// @return currentStrategy The current Strategy (from the Parent peer)
    function getCurrentStrategy() external view returns (IYieldPeer.Strategy memory currentStrategy) {
        currentStrategy = IParentPeer(i_parentPeer).getStrategy();
    }
}
