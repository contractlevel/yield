// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {DeployMockAaveNoYield, HelperConfig} from "../../../script/deploy/mocks/DeployMockAaveNoYield.s.sol";
import {MockAaveNoYield, DataTypes} from "../../mocks/testnet/MockAaveNoYield.sol";
import {MockAToken} from "../../mocks/MockAToken.sol";
import {MockUsdc} from "../../mocks/MockUsdc.sol";

contract MockAaveNoYieldTest is Test {
    MockAaveNoYield public mockAaveNoYield;
    MockUsdc public mockUsdc;
    MockAToken public mockAToken;
    address public user = makeAddr("user");

    function setUp() public {
        DeployMockAaveNoYield deployer = new DeployMockAaveNoYield();
        (HelperConfig config, MockAaveNoYield _mockAaveNoYield, MockAToken _mockAToken,) = deployer.run();
        mockAaveNoYield = _mockAaveNoYield;
        mockAToken = _mockAToken;
        HelperConfig.NetworkConfig memory networkConfig = config.getActiveNetworkConfig();
        mockUsdc = MockUsdc(networkConfig.tokens.usdc);

        deal(address(mockUsdc), user, 100);
    }

    function test_mockAaveNoYield_supply_updatesBalance() public {
        uint256 usdcBalanceBefore = mockUsdc.balanceOf(user);
        uint256 aaveBalanceBefore = mockAaveNoYield.balanceOf(user);

        vm.prank(user);
        mockUsdc.approve(address(mockAaveNoYield), 100);
        vm.prank(user);
        mockAaveNoYield.supply(address(0), 100, user, 0);

        assertEq(mockAaveNoYield.balanceOf(user), 100);
        assertEq(mockUsdc.balanceOf(user), usdcBalanceBefore - 100);
        assertEq(mockUsdc.balanceOf(address(mockAaveNoYield)), aaveBalanceBefore + 100);

        vm.prank(mockAaveNoYield.owner());
        mockAaveNoYield.setPeer(user);

        vm.prank(user);
        mockAaveNoYield.withdraw(address(0), 100, user);

        assertEq(mockAaveNoYield.balanceOf(user), 0);
        assertEq(mockUsdc.balanceOf(user), usdcBalanceBefore);
        assertEq(mockUsdc.balanceOf(address(mockAaveNoYield)), aaveBalanceBefore);
    }

    function test_mockAaveNoYield_getReserveData_returnsCorrectData() public view {
        DataTypes.ReserveData memory reserveData = mockAaveNoYield.getReserveData(address(0));
        assertEq(reserveData.aTokenAddress, address(mockAToken));
    }

    function test_mockAaveNoYield_setATokenAddress_revertsWhen_notOwner() public {
        vm.prank(user);
        vm.expectRevert();
        mockAaveNoYield.setATokenAddress(address(mockAToken));
    }

    function test_mockAaveNoYield_withdraw_revertsWhen_notPeer() public {
        vm.prank(user);
        vm.expectRevert();
        mockAaveNoYield.withdraw(address(0), 100, user);
    }

    function test_mockAaveNoYield_withdraw_revertsWhen_insufficientBalance() public {
        vm.prank(mockAaveNoYield.owner());
        mockAaveNoYield.setPeer(user);
        vm.prank(user);
        vm.expectRevert();
        mockAaveNoYield.withdraw(address(0), 100, user);
    }
}
