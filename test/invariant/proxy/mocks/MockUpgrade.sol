// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ParentPeer, Initializable} from "src/peers/ParentPeer.sol";
import {ChildPeer} from "src/peers/ChildPeer.sol";
import {Share} from "src/token/Share.sol";
import {Rebalancer} from "src/modules/Rebalancer.sol";
import {StrategyRegistry} from "src/modules/StrategyRegistry.sol";

/**
 * @title MockUpgrade
 * @notice Mock Upgrades for upgradeable contracts using ERC-7201 Namespaced Storage
 */

// Shared Storage + New Logic for all contracts
contract MockUpgradeStorage is Initializable {
    struct MockStorage {
        uint256 newVal;
        uint64 version;
    }

    // ERC-7201: keccak256(abi.encode(uint256(keccak256("yieldcoin.mock.storage.upgrade")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant MOCK_STORAGE_LOCATION = 0x3d1ed02e33f49bfa1786d2e4b2bea09a867fb139689efb2ef16682a097665b00;

    function _getMockStorage() internal pure returns (MockStorage storage $) {
        assembly { $.slot := MOCK_STORAGE_LOCATION }
    }

    function initializeDynamic(uint64 newVersion, uint256 val) public reinitializer(newVersion) {
        MockStorage storage $ = _getMockStorage();
        $.newVal = val;
        $.version = newVersion;
    }

    function version() external view returns (uint64) {
        return _getMockStorage().version;
    }

    function getNewVal() external view returns (uint256) {
        return _getMockStorage().newVal;
    }
}

// Parent & Child Peers
contract MockUpgradeParentPeer is MockUpgradeStorage, ParentPeer {
    constructor(address r, address l, uint64 c, address u, address s) ParentPeer(r, l, c, u, s) {}
}

contract MockUpgradeChildPeer is MockUpgradeStorage, ChildPeer {
    constructor(address r, address l, uint64 c, address u, address s, uint64 p) ChildPeer(r, l, c, u, s, p) {}
}

// Share
contract MockUpgradeShare is MockUpgradeStorage, Share {}

// Rebalancer
contract MockUpgradeRebalancer is MockUpgradeStorage, Rebalancer {}

// Strategy Registry
contract MockUpgradeStrategyRegistry is MockUpgradeStorage, StrategyRegistry {}
