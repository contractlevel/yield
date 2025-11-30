// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {CREReceiver} from "./CREReceiver.sol";
import {IParentPeer, IYieldPeer} from "../interfaces/IParentPeer.sol";

/// @title Rebalancer
/// @author George Gorzhiyev - Judge Finance
/// @notice A minimal version of the previous YieldCoin Rebalancer
contract Rebalancer is CREReceiver {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    address internal s_parentPeer;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the ParentPeer contract address is set
    event ParentPeerSet(address indexed parentPeer);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    function _processReport(bytes calldata report) internal override {
        // DO STUFF! :)
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the ParentPeer contract address
    /// @param parentPeer The address of the ParentPeer contract
    /// @dev Revert if the caller is not the config admin
    function setParentPeer(address parentPeer) external onlyOwner {
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
}
