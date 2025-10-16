// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";
import {StablecoinRegistry} from "../../../src/modules/StablecoinRegistry.sol";

contract SetStablecoinTest is BaseTest {
    StablecoinRegistry.Stablecoin public usdcStablecoin;

    function test_yield_stablecoinRegistry_setStablecoin_revertsWhen_notOwner() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseStablecoinRegistry.setStablecoin(keccak256(abi.encodePacked("usdc")), usdcStablecoin);
    }

    function test_yield_stablecoinRegistry_setStablecoin_success() public {
        bytes32 usdcId = keccak256(abi.encodePacked("usdcAddress"));
        address usdc = address(baseUsdc);
        uint8 decimals = baseUsdc.decimals();
        usdcStablecoin = StablecoinRegistry.Stablecoin(usdc, decimals);

        _changePrank(baseStablecoinRegistry.owner());
        baseStablecoinRegistry.setStablecoin(usdcId, usdcStablecoin);
        assertEq(baseStablecoinRegistry.getStablecoin(usdcId).stablecoin, usdc);
        assertEq(baseStablecoinRegistry.getStablecoin(usdcId).decimals, decimals);
    }
}
