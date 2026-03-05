// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @dev Empty implementation contract to be used with a circular dependancy where a Proxy needs to be deployed
/// in order to be used with another implementation contract. This allows us to deploy the Proxy first,
/// and then upgrade it to the actual implementation contract after.
contract EmptyImpl is Initializable, UUPSUpgradeable {
    error EmptyImpl__OnlyOwner();

    address internal immutable i_owner;

    constructor() {
        i_owner = msg.sender;
        _disableInitializers();
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert EmptyImpl__OnlyOwner();
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {}
}
