// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";

contract SetterTest is BaseTest {
    /*//////////////////////////////////////////////////////////////
                            STRATEGY ADAPTER
    //////////////////////////////////////////////////////////////*/
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

    /*//////////////////////////////////////////////////////////////
                              STABLECOINS
    //////////////////////////////////////////////////////////////*/
    function test_yield_strategyRegistry_setStablecoin_revertsWhen_notOwner() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseStrategyRegistry.setStablecoin(USDC_ID, address(0));
    }

    function test_yield_strategyRegistry_setStablecoin_success() public {
        _changePrank(baseStrategyRegistry.owner());
        baseStrategyRegistry.setStablecoin(USDC_ID, address(baseUsdc));
        assertEq(baseStrategyRegistry.getStablecoin(USDC_ID), address(baseUsdc));
        assertEq(baseStrategyRegistry.isStablecoinSupported(USDC_ID), true);
    }
}
