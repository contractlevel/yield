// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {CREReceiver} from "./CREReceiver.sol";
import {IParentPeer, IYieldPeer} from "../interfaces/IParentPeer.sol";

/// @title Rebalancer
/// @author George Gorzhiyev - Judge Finance
/// @notice A minimal version of the previous YieldCoin Rebalancer.
/// @notice Decodes verified CRE report and sets new Strategy on Parent peer.
contract Rebalancer is CREReceiver {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Rebalancer__NotZeroAddress();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev ParentPeer contract address
    address internal s_parentPeer;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the CRE report is successfully decoded/processed
    event ReportDecoded(uint64 indexed chainSelector, bytes32 indexed protocolId);
    /// @notice Emitted when the ParentPeer contract address is set
    event ParentPeerSet(address indexed parentPeer);
    /// @notice Emitted when the strategy registry is set
    event StrategyRegistrySet(address indexed strategyRegistry);

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

        IParentPeer(s_parentPeer).rebalance(newStrategy);
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
        s_parentPeer = parentPeer;
        emit ParentPeerSet(parentPeer);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @return parentPeer The ParentPeer contract address
    function getParentPeer() external view returns (address parentPeer) {
        parentPeer = s_parentPeer;
    }

    /// @dev Helper function to expose the Strategy struct for CRE to create Go bindings for encoding
    /// @return currentStrategy The current Strategy (from the Parent peer)
    function getCurrentStrategy() external view returns (IYieldPeer.Strategy memory currentStrategy) {
        currentStrategy = IParentPeer(s_parentPeer).getStrategy();
    }
}
