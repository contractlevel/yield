// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IERC20, Vm, console2} from "../../BaseTest.t.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
import {IComet} from "../../../src/interfaces/IComet.sol";
import {IYieldPeer} from "../../../src/interfaces/IYieldPeer.sol";
import {USDCTokenPool} from "@chainlink/contracts/src/v0.8/ccip/pools/USDC/USDCTokenPool.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {CCTPMessageTransmitterProxy} from
    "@chainlink/contracts/src/v0.8/ccip/pools/USDC/CCTPMessageTransmitterProxy.sol";

contract ParentDepositTest is BaseTest {
    function setUp() public override {
        super.setUp();
        /// @dev arbFork is the parent chain
        _selectFork(arbFork);
        deal(address(arbUsdc), depositor, DEPOSIT_AMOUNT);
        _changePrank(depositor);
        arbUsdc.approve(address(arbParentPeer), DEPOSIT_AMOUNT);
    }

    function test_yield_parent_deposit_revertsWhen_zeroAmount() public {
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__NoZeroAmount()"));
        arbParentPeer.deposit(0);
    }

    /// @notice Scenario: Deposit made on Parent chain, where the Strategy is, and the Strategy Protocol is Aave
    function test_yield_parent_deposit_strategyIsParent_aave() public {
        assertEq(arbShare.totalSupply(), 0);

        uint256 usdcBalanceBefore = arbUsdc.balanceOf(depositor);

        /// @dev act
        arbParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = arbUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev assert correct amount of shares minted
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(arbShare.totalSupply(), expectedShareMintAmount);
        assertEq(arbShare.balanceOf(depositor), expectedShareMintAmount);
        assertEq(arbParentPeer.getTotalShares(), expectedShareMintAmount);

        /// @dev assert USDC was deposited to Aave
        address aUsdc = _getATokenAddress(arbNetworkConfig.aavePoolAddressesProvider, address(arbUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(arbParentPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Deposit made on Parent chain, where the Strategy is, and the Strategy Protocol is Compound
    function test_yield_parent_deposit_strategyIsParent_compound() public {
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        arbParentPeer.setStrategy(arbChainSelector, IYieldPeer.Protocol.Compound);

        uint256 usdcBalanceBefore = arbUsdc.balanceOf(depositor);

        /// @dev act
        arbParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = arbUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev assert correct amount of shares minted
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(arbShare.totalSupply(), expectedShareMintAmount);
        assertEq(arbShare.balanceOf(depositor), expectedShareMintAmount);
        assertEq(arbParentPeer.getTotalShares(), expectedShareMintAmount);

        /// @dev assert USDC was deposited to Compound
        uint256 compoundBalance = IComet(arbNetworkConfig.comet).balanceOf(address(arbParentPeer));
        assertApproxEqAbs(
            compoundBalance,
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );

        // @review this is not a strictly necessary test, it could be used as a sanity check elsewhere later
        /// @dev assert balance increases with time
        vm.warp(block.timestamp + 10 days);
        assertGt(IComet(arbNetworkConfig.comet).balanceOf(address(arbParentPeer)), DEPOSIT_AMOUNT);
    }

    /// @notice Scenario: Deposit made on Parent chain, where the Strategy is not, and the Strategy Protocol is Aave
    function test_yield_parent_deposit_strategyIsChild_aave() public {
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        _selectFork(optFork);
        optChildPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(arbFork);
        arbParentPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);

        uint256 usdcBalanceBefore = arbUsdc.balanceOf(depositor);

        /// @dev act
        arbParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount on parent chain
        uint256 usdcBalanceAfter = arbUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev switch to child chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        /// @dev assert USDC was deposited to Aave on child chain
        address aUsdc = _getATokenAddress(optNetworkConfig.aavePoolAddressesProvider, address(optUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(optChildPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );

        /// @dev switch back to parent chain and route ccip message with totalValue to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);

        /// @dev assert correct amount of shares minted
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(arbShare.totalSupply(), expectedShareMintAmount);
        assertEq(arbShare.balanceOf(depositor), expectedShareMintAmount);
        assertEq(arbParentPeer.getTotalShares(), expectedShareMintAmount);
    }

    /// @notice Scenario: Deposit made on Parent chain, where the Strategy is not, and the Strategy Protocol is Compound
    function test_yield_parent_deposit_strategyIsChild_compound() public {
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        _selectFork(optFork);
        optChildPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(arbFork);
        arbParentPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Compound);

        uint256 usdcBalanceBefore = arbUsdc.balanceOf(depositor);

        /// @dev act
        arbParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount on parent chain
        uint256 usdcBalanceAfter = arbUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev switch to child chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        /// @dev assert USDC was deposited to Compound on child chain
        uint256 compoundBalance = IComet(optNetworkConfig.comet).balanceOf(address(optChildPeer));
        assertApproxEqAbs(
            compoundBalance,
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );

        /// @dev switch back to parent chain and route ccip message with totalValue to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);

        /// @dev assert correct amount of shares minted
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(arbShare.totalSupply(), expectedShareMintAmount);
        assertEq(arbShare.balanceOf(depositor), expectedShareMintAmount);
        assertEq(arbParentPeer.getTotalShares(), expectedShareMintAmount);
    }
}
