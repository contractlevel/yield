// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, console2, IYieldPeer, Log} from "../../BaseTest.t.sol";

contract CheckLogTest is BaseTest {
    /// @notice This test will have to be commented out along with the cannotExecute modifier in the ParentRebalancer contract, if running the entire test suite
    // function test_yield_rebalancer_checkLog_revertsWhen_cannotExecute() public {
    //     Log memory log =
    //         _createStrategyUpdatedLog(address(baseParentPeer), 1, keccak256(abi.encodePacked("aave-v3")), 3);
    //     vm.expectRevert(abi.encodeWithSignature("OnlySimulatedBackend()"));
    //     baseRebalancer.checkLog(log, "");
    // }

    /// @notice The cannotExecute modifier will need to be commented out for this test to pass
    function test_yield_rebalancer_checkLog_revertsWhen_wrongEvent() public {
        bytes32 wrongEvent = keccak256("WrongEvent()");
        bytes32[] memory topics = new bytes32[](1);
        topics[0] = wrongEvent;
        Log memory log = _createLog(address(baseParentPeer), topics);
        vm.expectRevert(abi.encodeWithSignature("Rebalancer__UpkeepNotNeeded()"));
        baseRebalancer.checkLog(log, "");
    }

    /// @notice The cannotExecute modifier will need to be commented out for this test to pass
    function test_yield_rebalancer_checkLog_revertsWhen_wrongSource() public {
        address wrongSource = makeAddr("wrongSource");
        Log memory log = _createStrategyUpdatedLog(wrongSource, 1, keccak256(abi.encodePacked("aave-v3")), 3);
        vm.expectRevert(abi.encodeWithSignature("Rebalancer__UpkeepNotNeeded()"));
        baseRebalancer.checkLog(log, "");
    }

    /// @notice The cannotExecute modifier will need to be commented out for this test to pass
    function test_yield_rebalancer_checkLog_revertsWhen_localParentRebalance() public {
        uint64 parentChainSelector = baseParentPeer.getThisChainSelector();
        Log memory log = _createStrategyUpdatedLog(address(baseParentPeer), parentChainSelector, 0, parentChainSelector);
        vm.expectRevert(abi.encodeWithSignature("Rebalancer__UpkeepNotNeeded()"));
        baseRebalancer.checkLog(log, "");
    }

    /// @notice The cannotExecute modifier will need to be commented out for this test to pass
    function test_yield_rebalancer_checkLog_rebalanceNewStrategy() public view {
        uint64 parentChainSelector = baseParentPeer.getThisChainSelector();
        uint64 newChainSelector = optChainSelector;
        bytes32 newProtocolId = keccak256(abi.encodePacked("compound-v3"));

        Log memory log =
            _createStrategyUpdatedLog(address(baseParentPeer), newChainSelector, newProtocolId, parentChainSelector);
        (bool upkeepNeeded, bytes memory performData) = baseRebalancer.checkLog(log, "");
        assertTrue(upkeepNeeded);

        (
            address parentPeer,
            IYieldPeer.Strategy memory newStrategy,
            IYieldPeer.CcipTxType txType,
            uint64 oldChainSelector,
            address oldStrategyAdapter,
            uint256 totalValue
        ) = abi.decode(performData, (address, IYieldPeer.Strategy, IYieldPeer.CcipTxType, uint64, address, uint256));
        assertEq(parentPeer, address(baseRebalancer.getParentPeer()));
        assertEq(newStrategy.chainSelector, newChainSelector);
        assertEq(newStrategy.protocolId, newProtocolId);
        assertEq(uint8(txType), uint8(IYieldPeer.CcipTxType.RebalanceNewStrategy));
        assertEq(oldChainSelector, parentChainSelector);
        assertEq(oldStrategyAdapter, address(baseParentPeer.getActiveStrategyAdapter()));
        assertEq(totalValue, baseParentPeer.getTotalValue());
    }

    function test_yield_rebalancer_checkLog_rebalanceOldStrategy() public view {
        uint64 newChainSelector = optChainSelector;
        uint64 oldChainSelector = ethChainSelector;
        bytes32 newProtocolId = keccak256(abi.encodePacked("compound-v3"));

        Log memory log =
            _createStrategyUpdatedLog(address(baseParentPeer), newChainSelector, newProtocolId, oldChainSelector);
        (bool upkeepNeeded, bytes memory performData) = baseRebalancer.checkLog(log, "");
        assertTrue(upkeepNeeded);

        (
            address parentPeer,
            IYieldPeer.Strategy memory newStrategy,
            IYieldPeer.CcipTxType txType,
            uint64 decodedOldChainSelector,
            address oldStrategyAdapter,
            uint256 totalValue
        ) = abi.decode(performData, (address, IYieldPeer.Strategy, IYieldPeer.CcipTxType, uint64, address, uint256));
        assertEq(parentPeer, address(baseRebalancer.getParentPeer()));
        assertEq(newStrategy.chainSelector, newChainSelector);
        assertEq(newStrategy.protocolId, newProtocolId);
        assertEq(uint8(txType), uint8(IYieldPeer.CcipTxType.RebalanceOldStrategy));
        assertEq(decodedOldChainSelector, oldChainSelector);
        assertEq(oldStrategyAdapter, address(baseParentPeer.getActiveStrategyAdapter()));
        assertEq(totalValue, 0);
    }

    /*//////////////////////////////////////////////////////////////
                                UTILITY
    //////////////////////////////////////////////////////////////*/
    function _createStrategyUpdatedLog(
        address source,
        uint64 newChainSelector,
        bytes32 newProtocolId,
        uint64 oldChainSelector
    ) internal view returns (Log memory) {
        bytes32 strategyUpdatedEvent = keccak256("StrategyUpdated(uint64,bytes32,uint64)");
        bytes32[] memory topics = new bytes32[](4);
        topics[0] = strategyUpdatedEvent;
        topics[1] = bytes32(uint256(newChainSelector));
        topics[2] = newProtocolId;
        topics[3] = bytes32(uint256(oldChainSelector));
        return _createLog(source, topics);
    }
}
