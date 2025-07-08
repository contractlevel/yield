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
import {ParentPeer} from "../../../src/peers/ParentPeer.sol";

contract ParentDepositTest is BaseTest {
    function setUp() public override {
        super.setUp();
        /// @dev baseFork is the parent chain
        _selectFork(baseFork);
        deal(address(baseUsdc), depositor, DEPOSIT_AMOUNT);
        _changePrank(depositor);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
    }

    function test_yield_parent_deposit_revertsWhen_insufficientAmount() public {
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__InsufficientAmount()"));
        baseParentPeer.deposit(1e6 - 1);
    }

    /// @notice Scenario: Deposit made on Parent chain, where the Strategy is, and the Strategy Protocol is Aave
    function test_yield_parent_deposit_strategyIsParent_aave() public {
        assertEq(baseShare.totalSupply(), 0);

        uint256 usdcBalanceBefore = baseUsdc.balanceOf(depositor);

        /// @dev act
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = baseUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev assert correct amount of shares minted
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.totalSupply(), expectedShareMintAmount);
        assertEq(baseShare.balanceOf(depositor), expectedShareMintAmount);
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);

        /// @dev assert USDC was deposited to Aave
        address aUsdc = _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseParentPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Deposit made on Parent chain, where the Strategy is, and the Strategy Protocol is Compound
    function test_yield_parent_deposit_strategyIsParent_compound() public {
        _setStrategy(baseChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(baseFork);
        _changePrank(depositor);

        uint256 usdcBalanceBefore = baseUsdc.balanceOf(depositor);

        /// @dev act
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = baseUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev assert correct amount of shares minted
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.totalSupply(), expectedShareMintAmount);
        assertEq(baseShare.balanceOf(depositor), expectedShareMintAmount);
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);

        /// @dev assert USDC was deposited to Compound
        uint256 compoundBalance = IComet(baseNetworkConfig.protocols.comet).balanceOf(address(baseParentPeer));
        assertApproxEqAbs(
            compoundBalance,
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );

        /// @dev assert balance increases with time
        vm.warp(block.timestamp + 10 days);
        assertGt(IComet(baseNetworkConfig.protocols.comet).balanceOf(address(baseParentPeer)), DEPOSIT_AMOUNT);
    }

    /// @notice Scenario: Deposit made on Parent chain, where the Strategy is not, and the Strategy Protocol is Aave
    function test_yield_parent_deposit_strategyIsChild_aave() public {
        _setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(baseFork);
        _changePrank(depositor);

        uint256 usdcBalanceBefore = baseUsdc.balanceOf(depositor);

        /// @dev act
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount on parent chain
        uint256 usdcBalanceAfter = baseUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev switch to child chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        /// @dev assert USDC was deposited to Aave on child chain
        address aUsdc = _getATokenAddress(optNetworkConfig.protocols.aavePoolAddressesProvider, address(optUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(optChildPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );

        /// @dev switch back to parent chain and route ccip message with totalValue to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev assert correct amount of shares minted
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.totalSupply(), expectedShareMintAmount);
        assertEq(baseShare.balanceOf(depositor), expectedShareMintAmount);
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);
    }

    /// @notice Scenario: Deposit made on Parent chain, where the Strategy is not, and the Strategy Protocol is Compound
    function test_yield_parent_deposit_strategyIsChild_compound() public {
        _setStrategy(optChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(baseFork);
        _changePrank(depositor);

        uint256 usdcBalanceBefore = baseUsdc.balanceOf(depositor);

        /// @dev act
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount on parent chain
        uint256 usdcBalanceAfter = baseUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev switch to child chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        /// @dev assert USDC was deposited to Compound on child chain
        uint256 compoundBalance = IComet(optNetworkConfig.protocols.comet).balanceOf(address(optChildPeer));
        assertApproxEqAbs(
            compoundBalance,
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );

        /// @dev switch back to parent chain and route ccip message with totalValue to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev assert correct amount of shares minted
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.totalSupply(), expectedShareMintAmount);
        assertEq(baseShare.balanceOf(depositor), expectedShareMintAmount);
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);
    }

    function test_yield_parent_deposit_multipleDeposits() public {
        /// @dev arrange
        address depositor2 = makeAddr("depositor2");
        deal(address(baseUsdc), depositor2, DEPOSIT_AMOUNT);
        _changePrank(depositor2);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);

        _changePrank(depositor);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev assert correct amount of shares minted
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.totalSupply(), expectedShareMintAmount);
        assertEq(baseShare.balanceOf(depositor), expectedShareMintAmount);

        /// @dev act
        _changePrank(depositor2);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert correct amount of shares minted for second deposit
        uint256 totalValue = baseParentPeer.getTotalValue();
        uint256 expectedSecondShareMintAmount =
            (_convertUsdcToShare(DEPOSIT_AMOUNT) * baseShare.totalSupply()) / _convertUsdcToShare(totalValue);
        uint256 yieldDifference = 6e11;
        assertApproxEqAbs(
            baseShare.totalSupply(), expectedShareMintAmount + expectedSecondShareMintAmount, yieldDifference
        );
        assertApproxEqAbs(baseShare.balanceOf(depositor2), expectedSecondShareMintAmount, yieldDifference);
    }

    function test_yield_calculateMintAmount_edgeCase() public {
        ParentWrapper parentWrapper = new ParentWrapper();
        parentWrapper.setTotalShares(100000000000000000001);
        uint256 totalValue = 100000000000000000001000001;
        uint256 totalShares = 100000000000000000001;
        uint256 amount = 1e6;
        parentWrapper.setTotalShares(totalShares);
        assertEq(parentWrapper.calculateMintAmount(totalValue, amount), 1);
    }
}

contract ParentWrapper is ParentPeer {
    constructor() ParentPeer(address(1), address(1), 1, address(1), address(1), address(1)) {}

    function setTotalShares(uint256 totalShares) public {
        s_totalShares = totalShares;
    }

    function calculateMintAmount(uint256 totalValue, uint256 amount) public view returns (uint256) {
        return _calculateMintAmount(totalValue, amount);
    }
}
