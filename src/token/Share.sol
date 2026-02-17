// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BurnMintERC677} from "@chainlink/contracts/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";
import {IGetCCIPAdmin} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IGetCCIPAdmin.sol";

/// @notice Deployer must grant mint and burn roles to (crosschain) Yield contracts
contract Share is BurnMintERC677, IGetCCIPAdmin {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev the CCIPAdmin can be used to register with the CCIP token admin registry, but has no other special powers,
    /// and can only be transferred by the owner.
    address internal s_ccipAdmin;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the CCIPAdmin role is transferred
    event CCIPAdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    // @review ccipAdmin should be passed or transferred in deploy script
    constructor() BurnMintERC677("YieldCoin", "YIELD", 18, 0) {
        s_ccipAdmin = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Transfers the CCIPAdmin role to a new address
    /// @dev only the owner can call this function, NOT the current ccipAdmin, and 2-step ownership transfer is used.
    /// @param newAdmin The address to transfer the CCIPAdmin role to. Setting to address(0) is a valid way to revoke
    /// the role
    //slither-disable-next-line missing-zero-check
    function setCCIPAdmin(address newAdmin) external onlyOwner {
        address currentAdmin = s_ccipAdmin;

        s_ccipAdmin = newAdmin;

        emit CCIPAdminTransferred(currentAdmin, newAdmin);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the current CCIPAdmin
    function getCCIPAdmin() external view returns (address) {
        return s_ccipAdmin;
    }
}
