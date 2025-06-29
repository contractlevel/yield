// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseTest, Vm, console2, IYieldPeer, Log} from "../../BaseTest.t.sol";

contract CheckLogTest is BaseTest {
    /// @notice This test will have to be commented out along with the cannotExecute modifier in the ParentRebalancer contract, if running the entire test suite
    function test_yield_checkLog_revertsWhen_cannotExecute() public {
        Log memory log = _createStrategyUpdatedLog(address(baseParentPeer), 1, 2, 3);
        vm.expectRevert(abi.encodeWithSignature("OnlySimulatedBackend()"));
        baseParentRebalancer.checkLog(log, "");
    }

    /// @notice The cannotExecute modifier will need to be commented out for this test to pass
    function test_yield_checkLog_revertsWhen_wrongEvent() public {
        bytes32 wrongEvent = keccak256("WrongEvent()");
        bytes32[] memory topics = new bytes32[](1);
        topics[0] = wrongEvent;
        Log memory log = _createLog(address(baseParentPeer), topics);
        vm.expectRevert(abi.encodeWithSignature("ParentRebalancer__UpkeepNotNeeded()"));
        baseParentRebalancer.checkLog(log, "");
    }

    /// @notice The cannotExecute modifier will need to be commented out for this test to pass
    function test_yield_checkLog_revertsWhen_wrongSource() public {
        address wrongSource = makeAddr("wrongSource");
        Log memory log = _createStrategyUpdatedLog(wrongSource, 1, 2, 3);
        vm.expectRevert(abi.encodeWithSignature("ParentRebalancer__UpkeepNotNeeded()"));
        baseParentRebalancer.checkLog(log, "");
    }

    /// @notice The cannotExecute modifier will need to be commented out for this test to pass
    function test_yield_checkLog_revertsWhen_localParentRebalance() public {
        uint64 parentChainSelector = baseParentPeer.getThisChainSelector();
        Log memory log = _createStrategyUpdatedLog(address(baseParentPeer), parentChainSelector, 0, parentChainSelector);
        vm.expectRevert(abi.encodeWithSignature("ParentRebalancer__UpkeepNotNeeded()"));
        baseParentRebalancer.checkLog(log, "");
    }

    /// @notice The cannotExecute modifier will need to be commented out for this test to pass
    function test_yield_checkLog_rebalanceNewStrategy() public view {
        uint64 parentChainSelector = baseParentPeer.getThisChainSelector();
        uint64 newChainSelector = optChainSelector;
        uint8 newProtocolEnum = uint8(IYieldPeer.Protocol.Aave);

        Log memory log =
            _createStrategyUpdatedLog(address(baseParentPeer), newChainSelector, newProtocolEnum, parentChainSelector);
        (bool upkeepNeeded, bytes memory performData) = baseParentRebalancer.checkLog(log, "");
        assertTrue(upkeepNeeded);

        (
            address forwarder,
            address parentPeer,
            IYieldPeer.Strategy memory newStrategy,
            IYieldPeer.CcipTxType txType,
            uint64 oldChainSelector,
            address oldStrategyPool,
            uint256 totalValue
        ) = abi.decode(
            performData, (address, address, IYieldPeer.Strategy, IYieldPeer.CcipTxType, uint64, address, uint256)
        );
        assertEq(forwarder, address(baseParentRebalancer.getForwarder()));
        assertEq(parentPeer, address(baseParentRebalancer.getParentPeer()));
        assertEq(newStrategy.chainSelector, newChainSelector);
        assertEq(uint8(newStrategy.protocol), newProtocolEnum);
        assertEq(uint8(txType), uint8(IYieldPeer.CcipTxType.RebalanceNewStrategy));
        assertEq(oldChainSelector, parentChainSelector);
        assertEq(oldStrategyPool, address(baseParentPeer.getStrategyPool()));
        assertEq(totalValue, baseParentPeer.getTotalValue());
    }

    function test_yield_checkLog_rebalanceOldStrategy() public view {
        uint64 newChainSelector = optChainSelector;
        uint64 oldChainSelector = ethChainSelector;
        Log memory log = _createStrategyUpdatedLog(address(baseParentPeer), newChainSelector, 0, oldChainSelector);
        (bool upkeepNeeded, bytes memory performData) = baseParentRebalancer.checkLog(log, "");
        assertTrue(upkeepNeeded);

        (
            address forwarder,
            address parentPeer,
            IYieldPeer.Strategy memory newStrategy,
            IYieldPeer.CcipTxType txType,
            uint64 decodedOldChainSelector,
            address oldStrategyPool,
            uint256 totalValue
        ) = abi.decode(
            performData, (address, address, IYieldPeer.Strategy, IYieldPeer.CcipTxType, uint64, address, uint256)
        );
        assertEq(forwarder, address(baseParentRebalancer.getForwarder()));
        assertEq(parentPeer, address(baseParentRebalancer.getParentPeer()));
        assertEq(newStrategy.chainSelector, newChainSelector);
        assertEq(uint8(newStrategy.protocol), 0);
        assertEq(uint8(txType), uint8(IYieldPeer.CcipTxType.RebalanceOldStrategy));
        assertEq(decodedOldChainSelector, oldChainSelector);
        assertEq(oldStrategyPool, address(baseParentPeer.getStrategyPool()));
        assertEq(totalValue, 0);
    }

    /*//////////////////////////////////////////////////////////////
                                UTILITY
    //////////////////////////////////////////////////////////////*/
    function _createStrategyUpdatedLog(
        address source,
        uint64 newChainSelector,
        uint8 newProtocolEnum,
        uint64 oldChainSelector
    ) internal view returns (Log memory) {
        bytes32 strategyUpdatedEvent = keccak256("StrategyUpdated(uint64,uint8,uint64)");
        bytes32[] memory topics = new bytes32[](4);
        topics[0] = strategyUpdatedEvent;
        topics[1] = bytes32(uint256(newChainSelector));
        topics[2] = bytes32(uint256(newProtocolEnum));
        topics[3] = bytes32(uint256(oldChainSelector));
        return _createLog(source, topics);
    }
}
