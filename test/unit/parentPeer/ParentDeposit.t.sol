// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IERC20, Vm, console2} from "../../BaseTest.t.sol";
import {IPool} from "@aave/v3-origin/src/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {IComet} from "../../../src/interfaces/IComet.sol";
import {IYieldPeer} from "../../../src/interfaces/IYieldPeer.sol";
import {USDCTokenPool} from "@chainlink/contracts/src/v0.8/ccip/pools/USDC/USDCTokenPool.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {
    CCTPMessageTransmitterProxy
} from "@chainlink/contracts/src/v0.8/ccip/pools/USDC/CCTPMessageTransmitterProxy.sol";
import {ParentPeer} from "../../../src/peers/ParentPeer.sol";
import {Roles} from "../../../src/libraries/Roles.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

contract ParentDepositTest is BaseTest {
    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        /// @dev set the fee rate
        _setFeeRate(INITIAL_FEE_RATE);

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

    function test_yield_parent_deposit_revertsWhen_parentPaused() public {
        _changePrank(emergencyPauser);
        baseParentPeer.emergencyPause();
        _changePrank(depositor);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
    }

    /// @notice Scenario: Deposit made on Parent chain, where the Strategy is, and the Strategy Protocol is Aave
    function test_yield_parent_deposit_strategyIsParent_aave() public {
        assertEq(baseShare.totalSupply(), 0);

        uint256 usdcBalanceBefore = baseUsdc.balanceOf(depositor);
        uint256 fee = _getFee(DEPOSIT_AMOUNT);
        uint256 userPrincipal = DEPOSIT_AMOUNT - fee;
        uint256 baseParentUsdcBalanceBefore = baseUsdc.balanceOf(address(baseParentPeer));

        /// @dev act
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = baseUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev assert correct amount of shares minted
        uint256 expectedShareMintAmount = userPrincipal * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.totalSupply(), expectedShareMintAmount);
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);
        assertEq(baseShare.balanceOf(depositor), expectedShareMintAmount);
        /// @dev assert fee is taken from stablecoin deposit
        assertEq(baseUsdc.balanceOf(address(baseParentPeer)), baseParentUsdcBalanceBefore + fee);

        /// @dev assert USDC was deposited to Aave
        address aUsdc = _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseAaveV3Adapter)),
            userPrincipal,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to user principal (deposit amount - fee)"
        );
    }

    /// @notice Scenario: Deposit made on Parent chain, where the Strategy is, and the Strategy Protocol is Compound
    function test_yield_parent_deposit_strategyIsParent_compound() public {
        _setStrategy(baseChainSelector, keccak256("compound-v3"), SET_CROSS_CHAIN);
        _selectFork(baseFork);
        _changePrank(depositor);

        uint256 usdcBalanceBefore = baseUsdc.balanceOf(depositor);
        uint256 fee = _getFee(DEPOSIT_AMOUNT);
        uint256 userPrincipal = DEPOSIT_AMOUNT - fee;
        uint256 baseParentUsdcBalanceBefore = baseUsdc.balanceOf(address(baseParentPeer));

        /// @dev act
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = baseUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev assert correct amount of shares minted
        uint256 expectedShareMintAmount = userPrincipal * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.totalSupply(), expectedShareMintAmount);
        assertEq(baseShare.balanceOf(depositor), expectedShareMintAmount);
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);
        /// @dev assert fee is taken from stablecoin deposit
        assertEq(baseUsdc.balanceOf(address(baseParentPeer)), baseParentUsdcBalanceBefore + fee);

        /// @dev assert USDC was deposited to Compound
        uint256 compoundBalance = IComet(baseNetworkConfig.protocols.comet).balanceOf(address(baseCompoundV3Adapter));
        assertApproxEqAbs(
            compoundBalance,
            userPrincipal,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to user principal (deposit amount - fee)"
        );

        /// @dev assert balance increases with time
        vm.warp(block.timestamp + 10 days);
        assertGt(IComet(baseNetworkConfig.protocols.comet).balanceOf(address(baseCompoundV3Adapter)), userPrincipal);
    }

    /// @notice Scenario: Deposit made on Parent chain, where the Strategy is not, and the Strategy Protocol is Aave
    function test_yield_parent_deposit_strategyIsChild_aave() public {
        _setStrategy(optChainSelector, keccak256("aave-v3"), SET_CROSS_CHAIN);
        _selectFork(baseFork);
        _changePrank(depositor);

        uint256 usdcBalanceBefore = baseUsdc.balanceOf(depositor);
        uint256 fee = _getFee(DEPOSIT_AMOUNT);
        uint256 userPrincipal = DEPOSIT_AMOUNT - fee;
        uint256 baseParentUsdcBalanceBefore = baseUsdc.balanceOf(address(baseParentPeer));

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
            IERC20(aUsdc).balanceOf(address(optAaveV3Adapter)),
            userPrincipal,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to user principal (deposit amount - fee)"
        );

        /// @dev switch back to parent chain and route ccip message with totalValue to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev assert correct amount of shares minted
        uint256 expectedShareMintAmount = userPrincipal * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.totalSupply(), expectedShareMintAmount);
        assertEq(baseShare.balanceOf(depositor), expectedShareMintAmount);
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);
        /// @dev assert fee is taken from stablecoin deposit
        assertEq(baseUsdc.balanceOf(address(baseParentPeer)), baseParentUsdcBalanceBefore + fee);
    }

    /// @notice Scenario: Deposit made on Parent chain, where the Strategy is not, and the Strategy Protocol is Compound
    function test_yield_parent_deposit_strategyIsChild_compound() public {
        _setStrategy(optChainSelector, keccak256("compound-v3"), SET_CROSS_CHAIN);
        _selectFork(baseFork);
        _changePrank(depositor);

        uint256 usdcBalanceBefore = baseUsdc.balanceOf(depositor);
        uint256 fee = _getFee(DEPOSIT_AMOUNT);
        uint256 userPrincipal = DEPOSIT_AMOUNT - fee;
        uint256 baseParentUsdcBalanceBefore = baseUsdc.balanceOf(address(baseParentPeer));

        /// @dev act
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount on parent chain
        uint256 usdcBalanceAfter = baseUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev switch to child chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        /// @dev assert USDC was deposited to Compound on child chain
        uint256 compoundBalance = IComet(optNetworkConfig.protocols.comet).balanceOf(address(optCompoundV3Adapter));
        assertApproxEqAbs(
            compoundBalance,
            userPrincipal,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to user principal (deposit amount - fee)"
        );

        /// @dev switch back to parent chain and route ccip message with totalValue to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev assert correct amount of shares minted
        uint256 expectedShareMintAmount = userPrincipal * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.totalSupply(), expectedShareMintAmount);
        assertEq(baseShare.balanceOf(depositor), expectedShareMintAmount);
        /// @dev assert fee is taken from stablecoin deposit
        assertEq(baseUsdc.balanceOf(address(baseParentPeer)), baseParentUsdcBalanceBefore + fee);
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);
    }

    function test_yield_parent_deposit_multipleDeposits() public {
        /// @dev arrange
        address depositor2 = makeAddr("depositor2");
        deal(address(baseUsdc), depositor2, DEPOSIT_AMOUNT);
        _changePrank(depositor2);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);

        uint256 fee = _getFee(DEPOSIT_AMOUNT);
        uint256 userPrincipal = DEPOSIT_AMOUNT - fee;
        uint256 baseParentUsdcBalanceBefore = baseUsdc.balanceOf(address(baseParentPeer));

        _changePrank(depositor);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev assert correct amount of shares minted
        uint256 expectedShareMintAmount = userPrincipal * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.totalSupply(), expectedShareMintAmount);
        assertEq(baseShare.balanceOf(depositor), expectedShareMintAmount);
        assertEq(baseUsdc.balanceOf(address(baseParentPeer)), baseParentUsdcBalanceBefore + fee);

        /// @dev act
        _changePrank(depositor2);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert correct amount of shares minted for second deposit
        uint256 totalValue = baseParentPeer.getTotalValue();
        uint256 expectedSecondShareMintAmount =
            (_convertUsdcToShare(userPrincipal) * baseShare.totalSupply()) / _convertUsdcToShare(totalValue);
        uint256 yieldDifference = 6e12;
        assertApproxEqAbs(baseShare.balanceOf(address(baseParentPeer)), fee * 2, yieldDifference);
        assertApproxEqAbs(
            baseShare.totalSupply(), expectedShareMintAmount + expectedSecondShareMintAmount, yieldDifference
        );
        assertApproxEqAbs(baseShare.balanceOf(depositor2), expectedSecondShareMintAmount - fee, yieldDifference);
        assertEq(baseUsdc.balanceOf(address(baseParentPeer)), baseParentUsdcBalanceBefore + (fee * 2));
    }

    function test_yield_calculateMintAmount_edgeCase() public {
        ParentWrapper parentWrapper = new ParentWrapper();
        parentWrapper.setTotalShares(100000000000000000001);
        uint256 totalValue = 100000000000000000001000001;
        uint256 totalShares = 100000000000000000001;
        uint256 amount = 1e6;
        parentWrapper.setTotalShares(totalShares);
        assertEq(parentWrapper.calculateMintAmount_(totalValue, amount), 1);
    }

    /// @notice Tests for deposit/withdraw when s_strategy points to parent but activeStrategyAdapter is 0
    /// @notice Deposit Scenario:
    /// 1. s_strategy is correctly set to point to parent chain
    /// 2. But activeStrategyAdapter is 0 (simulating the rebalance window)
    /// 3. User tries to deposit on parent
    function test_yield_parent_deposit_revertsWhen_strategyPointsToParent_butActiveAdapterIsZero() public {
        /// @dev Arrange: Set strategy to parent with Aave (this sets both s_strategy and activeStrategyAdapter)
        _setStrategy(baseChainSelector, keccak256(abi.encodePacked("aave-v3")), SET_CROSS_CHAIN);
        _selectFork(baseFork);
        _changePrank(depositor);

        /// @dev Verify s_strategy points to parent
        IYieldPeer.Strategy memory strategy = baseParentPeer.getStrategy();
        assertEq(strategy.chainSelector, baseChainSelector, "Strategy should point to parent");
        assertEq(strategy.protocolId, keccak256(abi.encodePacked("aave-v3")), "Strategy protocol should be aave-v3");

        /// @dev Verify activeStrategyAdapter is set correctly initially
        address activeStrategyAdapter = baseParentPeer.getActiveStrategyAdapter();
        assertTrue(activeStrategyAdapter != address(0), "ActiveStrategyAdapter should be set initially");
        assertEq(activeStrategyAdapter, address(baseAaveV3Adapter), "ActiveStrategyAdapter should be Aave adapter");

        /// @dev Simulate the rebalance window: manually set activeStrategyAdapter to 0
        /// @dev This simulates the state where s_strategy was updated but _handleCCIPRebalanceNewStrategy hasn't been called yet
        stdstore.target(address(baseParentPeer)).sig("getActiveStrategyAdapter()").checked_write(address(0));

        /// @dev Verify activeStrategyAdapter is now 0
        assertEq(baseParentPeer.getActiveStrategyAdapter(), address(0), "ActiveStrategyAdapter should be 0");

        /// @dev Verify s_strategy still points to parent
        strategy = baseParentPeer.getStrategy();
        assertEq(strategy.chainSelector, baseChainSelector, "Strategy should still point to parent");

        /// @dev Record initial state
        uint256 initialShareBalance = baseShare.balanceOf(depositor);
        uint256 initialTotalShares = baseParentPeer.getTotalShares();

        vm.expectRevert(abi.encodeWithSelector(ParentPeer.ParentPeer__InactiveStrategyAdapter.selector));
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev Assert: No shares should be minted (deposit should revert)
        assertEq(baseShare.balanceOf(depositor), initialShareBalance, "No shares should be minted");
        assertEq(baseParentPeer.getTotalShares(), initialTotalShares, "Total shares should not change");
    }
}

contract ParentWrapper is ParentPeer {
    constructor() ParentPeer(address(1), address(1), 1, address(1), address(1)) {}

    function setTotalShares(uint256 totalShares) public {
        s_totalShares = totalShares;
    }

    function calculateMintAmount_(uint256 totalValue, uint256 amount) public view returns (uint256) {
        return _calculateMintAmount(totalValue, amount);
    }
}
