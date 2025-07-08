// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, console2, IYieldPeer, Log, IPoolAddressesProvider} from "../../BaseTest.t.sol";

contract PerformUpkeepTest is BaseTest {
    function test_yield_performUpkeep_revertsWhen_notForwarder() public {
        bytes memory performData =
            _createPerformData(0, 0, IYieldPeer.CcipTxType.RebalanceNewStrategy, 0, address(0), 0);
        vm.expectRevert(abi.encodeWithSignature("ParentRebalancer__OnlyForwarder()"));
        baseParentRebalancer.performUpkeep(performData);
    }

    function test_yield_performUpkeep_rebalanceNewStrategy() public {
        address aavePool = IPoolAddressesProvider(baseAaveV3.getPoolAddressesProvider()).getPool();
        deal(address(baseUsdc), aavePool, DEPOSIT_AMOUNT);

        uint64 oldChainSelector = baseParentPeer.getThisChainSelector();
        uint8 newProtocolEnum = uint8(IYieldPeer.Protocol.Aave);
        uint64 newChainSelector = optChainSelector;
        address newStrategyPool = baseParentPeer.getActiveStrategyAdapter();
        uint256 totalValue = baseParentPeer.getTotalValue();
        bytes memory performData = _createPerformData(
            newChainSelector,
            newProtocolEnum,
            IYieldPeer.CcipTxType.RebalanceNewStrategy,
            oldChainSelector,
            newStrategyPool,
            totalValue
        );
        _changePrank(forwarder);
        vm.recordLogs();
        baseParentRebalancer.performUpkeep(performData);

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

    function test_yield_performUpkeep_rebalanceOldStrategy() public {
        address aavePool = IPoolAddressesProvider(baseAaveV3.getPoolAddressesProvider()).getPool();
        deal(address(baseUsdc), aavePool, DEPOSIT_AMOUNT);

        uint64 oldChainSelector = ethChainSelector;
        uint64 newChainSelector = optChainSelector;
        uint8 newProtocolEnum = uint8(IYieldPeer.Protocol.Aave);
        address newStrategyPool = baseParentPeer.getActiveStrategyAdapter();
        uint256 totalValue = baseParentPeer.getTotalValue();
        bytes memory performData = _createPerformData(
            newChainSelector,
            newProtocolEnum,
            IYieldPeer.CcipTxType.RebalanceOldStrategy,
            oldChainSelector,
            newStrategyPool,
            totalValue
        );
        _changePrank(forwarder);
        vm.recordLogs();
        baseParentRebalancer.performUpkeep(performData);

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
