// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, console2, IYieldPeer, Log, IPoolAddressesProvider} from "../../BaseTest.t.sol";

contract PerformUpkeepTest is BaseTest {
    function test_yield_rebalancer_performUpkeep_revertsWhen_notForwarder() public {
        vm.expectRevert(abi.encodeWithSignature("Rebalancer__OnlyForwarder()"));
        baseRebalancer.performUpkeep("");
    }

    function test_yield_rebalancer_performUpkeep_rebalanceNewStrategy() public {
        address aavePool = IPoolAddressesProvider(baseAaveV3Adapter.getPoolAddressesProvider()).getPool();
        deal(address(baseUsdc), aavePool, DEPOSIT_AMOUNT);

        uint64 oldChainSelector = baseParentPeer.getThisChainSelector();
        bytes32 newProtocolId = keccak256(abi.encodePacked("aave-v3"));
        uint64 newChainSelector = optChainSelector;
        address newStrategyPool = baseParentPeer.getActiveStrategyAdapter();
        uint256 totalValue = baseParentPeer.getTotalValue();
        bytes memory performData = _createPerformData(
            newChainSelector,
            newProtocolId,
            IYieldPeer.CcipTxType.RebalanceNewStrategy,
            oldChainSelector,
            newStrategyPool,
            totalValue
        );
        _changePrank(forwarder);
        vm.recordLogs();
        baseRebalancer.performUpkeep(performData);

        bytes32 ccipMessageSentEvent = keccak256("CCIPMessageSent(bytes32,uint8,uint256)");
        bool ccipMessageSentEventFound = false;
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == ccipMessageSentEvent) {
                ccipMessageSentEventFound = true;
                assertEq(uint8(uint256(logs[i].topics[2])), uint8(IYieldPeer.CcipTxType.RebalanceNewStrategy));
                assertEq(uint256(logs[i].topics[3]), totalValue);
            }
        }
        assertTrue(ccipMessageSentEventFound, "CCIPMessageSent log not found");
    }

    function test_yield_rebalancer_performUpkeep_rebalanceOldStrategy() public {
        address aavePool = IPoolAddressesProvider(baseAaveV3Adapter.getPoolAddressesProvider()).getPool();
        deal(address(baseUsdc), aavePool, DEPOSIT_AMOUNT);

        uint64 oldChainSelector = ethChainSelector;
        uint64 newChainSelector = optChainSelector;
        bytes32 newProtocolId = keccak256(abi.encodePacked("aave-v3"));
        address newStrategyPool = baseParentPeer.getActiveStrategyAdapter();
        uint256 totalValue = baseParentPeer.getTotalValue();
        bytes memory performData = _createPerformData(
            newChainSelector,
            newProtocolId,
            IYieldPeer.CcipTxType.RebalanceOldStrategy,
            oldChainSelector,
            newStrategyPool,
            totalValue
        );
        _changePrank(forwarder);
        vm.recordLogs();
        baseRebalancer.performUpkeep(performData);

        bytes32 ccipMessageSentEvent = keccak256("CCIPMessageSent(bytes32,uint8,uint256)");
        bool ccipMessageSentEventFound = false;
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == ccipMessageSentEvent) {
                ccipMessageSentEventFound = true;
                assertEq(uint8(uint256(logs[i].topics[2])), uint8(IYieldPeer.CcipTxType.RebalanceOldStrategy));
                assertEq(uint256(logs[i].topics[3]), 0);
            }
        }
        assertTrue(ccipMessageSentEventFound, "CCIPMessageSent log not found");
    }
}
