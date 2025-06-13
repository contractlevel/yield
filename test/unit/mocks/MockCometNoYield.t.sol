// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {DeployMockCometNoYield} from "../../../script/deploy/mocks/DeployMockCometNoYield.s.sol";
import {MockCometNoYield} from "../../mocks/testnet/MockCometNoYield.sol";
import {MockUsdc} from "../../mocks/MockUsdc.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockCometNoYieldTest is Test {
    MockCometNoYield public comet;
    address internal peer = makeAddr("peer");
    address internal user = makeAddr("user");
    MockUsdc public usdc;
    uint256 internal amount = 100;

    function setUp() public {
        DeployMockCometNoYield deployer = new DeployMockCometNoYield();
        comet = deployer.run();
        usdc = new MockUsdc();
        deal(address(usdc), user, amount);
        vm.prank(user);
        usdc.approve(address(comet), amount);
    }

    function test_mockCometNoYield_setPeer() public {
        vm.prank(comet.owner());
        comet.setPeer(peer);
        assertEq(comet.getPeer(), peer);
    }

    function test_mockCometNoYield_setPeer_onlyOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        comet.setPeer(peer);
    }

    function test_mockCometNoYield_supply() public {
        uint256 balanceBefore = usdc.balanceOf(user);
        uint256 cometBalanceBefore = comet.balanceOf(user);
        vm.prank(user);
        comet.supply(address(usdc), amount);
        assertEq(usdc.balanceOf(user), balanceBefore - amount);
        assertEq(comet.balanceOf(user), cometBalanceBefore + amount);
    }

    function test_mockCometNoYield_withdraw() public {
        uint256 balanceBefore = usdc.balanceOf(user);
        uint256 cometBalanceBefore = comet.balanceOf(user);
        vm.prank(user);
        comet.supply(address(usdc), amount);
        vm.prank(comet.owner());
        comet.setPeer(user);
        vm.prank(user);
        comet.withdraw(address(usdc), amount);
        assertEq(usdc.balanceOf(user), balanceBefore);
        assertEq(comet.balanceOf(user), cometBalanceBefore);
    }

    function test_mockCometNoYield_withdraw_onlyPeer() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(MockCometNoYield.MockCometNoYield__OnlyPeer.selector));
        comet.withdraw(address(usdc), amount);
    }

    function test_mockCometNoYield_withdraw_revertsWhen_insufficientBalance() public {
        vm.prank(comet.owner());
        comet.setPeer(user);
        vm.prank(user);
        vm.expectRevert();
        comet.withdraw(address(usdc), amount);
    }
}
