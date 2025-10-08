// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {StablecoinRegistry} from "../../../src/modules/StablecoinRegistry.sol";

contract StablecoinSetter is Test {
    StablecoinRegistry public stablecoinRegistry;
    StablecoinRegistry.Stablecoin public usdcStablecoin;

    address public owner = makeAddr("owner");
    address public usdc = makeAddr("usdc");
    address public holder = makeAddr("holder");

    function setUp() public {
        vm.prank(owner);
        stablecoinRegistry = new StablecoinRegistry();
        usdcStablecoin = StablecoinRegistry.Stablecoin(address(usdc), 6);
    }

    function test_yield_stablecoinRegistry_setStablecoin_revertsWhen_notOwner() public {
        vm.prank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        stablecoinRegistry.setStablecoin(keccak256(abi.encodePacked("usdc")), usdcStablecoin);
    }

    function test_yield_stablecoinRegistry_setStablecoin_success() public {
        bytes32 usdcId = keccak256(abi.encodePacked("usdc"));

        vm.prank(owner);
        stablecoinRegistry.setStablecoin(usdcId, usdcStablecoin);
        assertEq(stablecoinRegistry.getStablecoin(usdcId).stablecoin, address(usdc));
        assertEq(stablecoinRegistry.getStablecoin(usdcId).decimals, 6);
    }
}
