// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ParentPeer} from "../../../../src/peers/ParentPeer.sol";
import {ChildPeer} from "../../../../src/peers/ChildPeer.sol";
import {Share} from "../../../../src/token/Share.sol";
import {Rebalancer} from "../../../../src/modules/Rebalancer.sol";
import {StrategyRegistry} from "../../../../src/modules/StrategyRegistry.sol";

/*//////////////////////////////////////////////////////////////
                         SHARED STORAGE
//////////////////////////////////////////////////////////////*/

/// @dev Shared namespace struct for all mocks to track version and fuzz values without storage collisions
struct MockStorage {
    uint256 newVal;
    uint64 version;
}

/*//////////////////////////////////////////////////////////////
                         SAFE UPGRADES
//////////////////////////////////////////////////////////////*/

// --- Parent Peer --- //
contract MockUpgradeParentPeer is ParentPeer {
    // keccak256(abi.encode(uint256(keccak256("mock.storage.parent")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant MOCK_STORAGE_LOCATION = 0x5726555848520268574404780540166660142252131938830846540306352300;

    constructor(address r, address l, uint64 c, address u, address s) ParentPeer(r, l, c, u, s) {}

    function _getMockStorage() private pure returns (MockStorage storage $) {
        assembly { $.slot := MOCK_STORAGE_LOCATION }
    }

    function version() external view returns (uint64) {
        return _getMockStorage().version;
    }

    function initializeDynamic(uint64 newVersion, uint256 val) external reinitializer(newVersion) {
        MockStorage storage $ = _getMockStorage();
        $.newVal = val;
        $.version = newVersion;
    }

    function getNewVal() external view returns (uint256) {
        return _getMockStorage().newVal;
    }
}

// --- Child Peer --- //
contract MockUpgradeChildPeer is ChildPeer {
    // keccak256(abi.encode(uint256(keccak256("mock.storage.child")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant MOCK_STORAGE_LOCATION = 0x9330101905391924611586520779836965006427387399818814725350319000;

    constructor(address r, address l, uint64 c, address u, address s, uint64 p) ChildPeer(r, l, c, u, s, p) {}

    function _getMockStorage() private pure returns (MockStorage storage $) {
        assembly { $.slot := MOCK_STORAGE_LOCATION }
    }

    function version() external view returns (uint64) {
        return _getMockStorage().version;
    }

    function initializeDynamic(uint64 newVersion, uint256 val) external reinitializer(newVersion) {
        MockStorage storage $ = _getMockStorage();
        $.newVal = val;
        $.version = newVersion;
    }

    function getNewVal() external view returns (uint256) {
        return _getMockStorage().newVal;
    }
}

// --- Share --- //
contract MockUpgradeShare is Share {
    // keccak256(abi.encode(uint256(keccak256("mock.storage.share")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant MOCK_STORAGE_LOCATION = 0xe410502157464069792070180491060908863649666070633842605805562000;

    function _getMockStorage() private pure returns (MockStorage storage $) {
        assembly { $.slot := MOCK_STORAGE_LOCATION }
    }

    function version() external view returns (uint64) {
        return _getMockStorage().version;
    }

    function initializeDynamic(uint64 newVersion, uint256 val) external reinitializer(newVersion) {
        MockStorage storage $ = _getMockStorage();
        $.newVal = val;
        $.version = newVersion;
    }

    function getNewVal() external view returns (uint256) {
        return _getMockStorage().newVal;
    }
}

// --- Rebalancer --- //
contract MockUpgradeRebalancer is Rebalancer {
    // keccak256(abi.encode(uint256(keccak256("mock.storage.rebalancer")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant MOCK_STORAGE_LOCATION = 0x8269785868846392095906322304895642646698144218331326467399580500;

    function _getMockStorage() private pure returns (MockStorage storage $) {
        assembly { $.slot := MOCK_STORAGE_LOCATION }
    }

    function version() external view returns (uint64) {
        return _getMockStorage().version;
    }

    function initializeDynamic(uint64 newVersion, uint256 val) external reinitializer(newVersion) {
        MockStorage storage $ = _getMockStorage();
        $.newVal = val;
        $.version = newVersion;
    }

    function getNewVal() external view returns (uint256) {
        return _getMockStorage().newVal;
    }
}

// --- Strategy Registry --- //
contract MockUpgradeStrategyRegistry is StrategyRegistry {
    // keccak256(abi.encode(uint256(keccak256("mock.storage.registry")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant MOCK_STORAGE_LOCATION = 0x6968032731802905353594833291845187796011985396557682245229618400;

    function _getMockStorage() private pure returns (MockStorage storage $) {
        assembly { $.slot := MOCK_STORAGE_LOCATION }
    }

    function version() external view returns (uint64) {
        return _getMockStorage().version;
    }

    function initializeDynamic(uint64 newVersion, uint256 val) external reinitializer(newVersion) {
        MockStorage storage $ = _getMockStorage();
        $.newVal = val;
        $.version = newVersion;
    }

    function getNewVal() external view returns (uint256) {
        return _getMockStorage().newVal;
    }
}

/*//////////////////////////////////////////////////////////////
                        UNSAFE UPGRADES
//////////////////////////////////////////////////////////////*/

// @review Upgrades with stuff to break contracts, not sure if we will use, it's more for sanity test to make sure
// the contracts break if corrupted.

/*

// --- Parent Peer Unsafe --- //
contract MockUpgradeParentPeerUnsafe is ParentPeer {
    bytes32 private constant MOCK_STORAGE_LOCATION = 0x5726555848520268574404780540166660142252131938830846540306352300;

    // Target slot to corrupt: ParentPeerStorage
    bytes32 private constant PARENT_PEER_STORAGE_LOCATION =
        0x603686382b15940b5fa7ef449162bde228a5948ce3b6bdf08bd833ec6ae79500;

    constructor(address r, address l, uint64 c, address u, address s) ParentPeer(r, l, c, u, s) {}

    function _getMockStorage() private pure returns (MockStorage storage $) {
        assembly { $.slot := MOCK_STORAGE_LOCATION }
    }

    function version() external view returns (uint64) {
        return _getMockStorage().version;
    }

    function initializeDynamic(uint64 newVersion, uint256 val) external reinitializer(newVersion) {
        // 1. CORRUPTION: Overwrite totalShares in ParentPeer storage
        bytes32 corruptionSlot = PARENT_PEER_STORAGE_LOCATION;
        assembly { sstore(corruptionSlot, val) }

        // 2. State: Update version so invariant knows upgrade happened
        MockStorage storage $ = _getMockStorage();
        $.version = newVersion;
    }

    function getNewVal() external view returns (uint256) {
        bytes32 slot = PARENT_PEER_STORAGE_LOCATION;
        uint256 val;
        assembly { val := sload(slot) }
        return val;
    }
}

// --- Child Peer Unsafe --- //
contract MockUpgradeChildPeerUnsafe is ChildPeer {
    bytes32 private constant MOCK_STORAGE_LOCATION = 0x9330101905391924611586520779836965006427387399818814725350319000;

    // Target slot: YieldPeerStorage
    bytes32 private constant YIELD_PEER_STORAGE_LOCATION =
        0x64ca1a4cbd2b05db1cf2adeaa253c530d3b0a11bd529ef6e3ea9005e6aabd600;

    constructor(address r, address l, uint64 c, address u, address s, uint64 p) ChildPeer(r, l, c, u, s, p) {}

    function _getMockStorage() private pure returns (MockStorage storage $) {
        assembly { $.slot := MOCK_STORAGE_LOCATION }
    }

    function version() external view returns (uint64) {
        return _getMockStorage().version;
    }

    function initializeDynamic(uint64 newVersion, uint256 val) external reinitializer(newVersion) {
        // 1. Corruption
        bytes32 slot = YIELD_PEER_STORAGE_LOCATION;
        assembly { sstore(slot, val) }

        // 2. Mock State
        MockStorage storage $ = _getMockStorage();
        $.version = newVersion;
    }

    function getNewVal() external view returns (uint256) {
        bytes32 slot = YIELD_PEER_STORAGE_LOCATION;
        uint256 val;
        assembly { val := sload(slot) }
        return val;
    }
}

// --- Rebalancer Unsafe --- //
contract MockUpgradeRebalancerUnsafe is Rebalancer {
    bytes32 private constant MOCK_STORAGE_LOCATION = 0x8269785868846392095906322304895642646698144218331326467399580500;
    // Target slot: RebalancerStorage
    bytes32 private constant REBALANCER_STORAGE_LOCATION =
        0xc3b8b4354c99bf0a184f0d594e91e4d4c7908c52392d7f7c7384b5f321e23c00;

    function _getMockStorage() private pure returns (MockStorage storage $) {
        assembly { $.slot := MOCK_STORAGE_LOCATION }
    }

    function version() external view returns (uint64) {
        return _getMockStorage().version;
    }

    function initializeDynamic(uint64 newVersion, uint256 val) external reinitializer(newVersion) {
        // 1. Corruption: Overwrite s_parentPeer (slot 0)
        bytes32 slot = REBALANCER_STORAGE_LOCATION;
        assembly { sstore(slot, val) }

        // 2. Mock State
        MockStorage storage $ = _getMockStorage();
        $.version = newVersion;
    }

    function getNewVal() external view returns (uint256) {
        bytes32 slot = REBALANCER_STORAGE_LOCATION;
        uint256 val;
        assembly { val := sload(slot) }
        return val;
    }
}

// --- Share Unsafe --- //
contract MockUpgradeShareUnsafe is Share {
    bytes32 private constant MOCK_STORAGE_LOCATION = 0xe410502157464069792070180491060908863649666070633842605805562000;
    // Exact hash from ERC20Upgradeable.sol
    bytes32 private constant ERC20_STORAGE_LOCATION =
        0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;

    function _getMockStorage() private pure returns (MockStorage storage $) {
        assembly { $.slot := MOCK_STORAGE_LOCATION }
    }

    function version() external view returns (uint64) {
        return _getMockStorage().version;
    }

    function initializeDynamic(uint64 newVersion, uint256 val) external reinitializer(newVersion) {
        // 1. Corruption: Target totalSupply slot (Slot 2 of struct)
        bytes32 totalSupplySlot = bytes32(uint256(ERC20_STORAGE_LOCATION) + 2);
        assembly { sstore(totalSupplySlot, val) }

        // 2. Mock State
        MockStorage storage $ = _getMockStorage();
        $.version = newVersion;
    }

    function getNewVal() external view returns (uint256) {
        bytes32 totalSupplySlot = bytes32(uint256(ERC20_STORAGE_LOCATION) + 2);
        uint256 val;
        assembly { val := sload(totalSupplySlot) }
        return val;
    }
}

// --- Strategy Registry Unsafe --- //
contract MockUpgradeStrategyRegistryUnsafe is StrategyRegistry {
    bytes32 private constant MOCK_STORAGE_LOCATION = 0x6968032731802905353594833291845187796011985396557682245229618400;
    // Target slot: StrategyRegistryStorage
    bytes32 private constant STRATEGY_REGISTRY_STORAGE_LOCATION =
        0xff4f32e19ccce71bf80077033cba16a319c7bee7ac2089685e40116337a8fe00;

    function _getMockStorage() private pure returns (MockStorage storage $) {
        assembly { $.slot := MOCK_STORAGE_LOCATION }
    }

    function version() external view returns (uint64) {
        return _getMockStorage().version;
    }

    function initializeDynamic(uint64 newVersion, uint256 val) external reinitializer(newVersion) {
        // 1. Corruption: Target Aave V3 mapping slot
        bytes32 protocolId = keccak256(abi.encodePacked("aave-v3"));
        bytes32 baseSlot = STRATEGY_REGISTRY_STORAGE_LOCATION;
        bytes32 mapSlot = keccak256(abi.encode(protocolId, baseSlot));

        address garbage = address(uint160(val));
        assembly { sstore(mapSlot, garbage) }

        // 2. Mock State
        MockStorage storage $ = _getMockStorage();
        $.version = newVersion;
    }

    function getNewVal() external pure returns (uint256) {
        return 1337;
    }
}

*/