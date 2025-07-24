// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";

contract SetterTest is BaseTest {
    function test_yield_strategyRegistry_setStrategyAdapter_revertsWhen_notOwner() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseStrategyRegistry.setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(baseAaveV3Adapter));
    }

    function test_yield_strategyRegistry_setStrategyAdapter_success() public {
        address newStrategyAdapter = makeAddr("newStrategyAdapter");
        bytes32 protocolId = keccak256(abi.encodePacked("test-protocol"));
        _changePrank(baseStrategyRegistry.owner());
        baseStrategyRegistry.setStrategyAdapter(protocolId, newStrategyAdapter);
        assertEq(baseStrategyRegistry.getStrategyAdapter(protocolId), newStrategyAdapter);
    }
}
