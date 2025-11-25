// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IERC20, Vm, console2} from "../../BaseTest.t.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
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
        _setStrategy(baseChainSelector, keccak256("compound-v3"));
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
        _setStrategy(optChainSelector, keccak256("aave-v3"));
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
        _setStrategy(optChainSelector, keccak256("compound-v3"));
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
    function test_yield_parent_deposit_strategyPointsToParent_butActiveAdapterIsZero_reverts() public {
        /// @dev Arrange: Set strategy to parent with Aave (this sets both s_strategy and activeStrategyAdapter)
        _setStrategy(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));
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

    /// @notice Withdraw Scenario: Withdraw on Parent, TVL in transit
    function test_yield_parent_withdraw_strategyPointsToParent_butActiveAdapterIsZero_reverts() public {
        /// @dev Arrange: Set strategy to parent with Aave and make a deposit first
        _setStrategy(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));
        _selectFork(baseFork);
        _changePrank(depositor);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev Get shares
        uint256 shareBalance = baseShare.balanceOf(depositor);
        assertGt(shareBalance, 0, "Shares should be minted");

        /// @dev Simulate the rebalance window: manually set activeStrategyAdapter to 0
        stdstore.target(address(baseParentPeer)).sig("getActiveStrategyAdapter()").checked_write(address(0));

        /// @dev Verify activeStrategyAdapter is now 0
        assertEq(baseParentPeer.getActiveStrategyAdapter(), address(0), "ActiveStrategyAdapter should be 0");

        /// @dev Act: Attempt to withdraw
        /// @dev This should revert with ParentPeer__InactiveStrategyAdapter()
        vm.expectRevert(abi.encodeWithSelector(ParentPeer.ParentPeer__InactiveStrategyAdapter.selector));
        baseShare.transferAndCall(address(baseParentPeer), shareBalance, "");

        /// @dev Assert: Shares should not be burned (withdraw should revert)
        assertEq(baseShare.balanceOf(depositor), shareBalance, "Shares should not be burned");
    }

    /// @notice Test: Withdraw ping-pong when parent is strategy but adapter is 0
    /// @notice Flow: Withdraw on child -> Parent is strategy (adapter=0) -> Parent ping-pongs -> Child retries
    /// @notice The ping-pong happens inside _handleCCIPWithdraw on the parent
    function test_yield_parent_handleCCIPWithdraw_pingPongWhenAdapterZero() public {
        /// @dev arrange: Strategy on BASE parent, deposit on OPT child so shares live on child chain
        _setStrategy(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));

        _selectFork(optFork);
        deal(address(optUsdc), withdrawer, DEPOSIT_AMOUNT);
        _changePrank(withdrawer);
        optUsdc.approve(address(optChildPeer), DEPOSIT_AMOUNT);
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev Complete deposit flow (OPT -> BASE strategy -> OPT shares)
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev arrange: Force adapter to 0 on BASE parent to simulate rebalance window
        _selectFork(baseFork);
        stdstore.target(address(baseParentPeer)).sig("getActiveStrategyAdapter()").checked_write(address(0));

        /// @dev arrange: Withdraw on OPT child
        _selectFork(optFork);
        uint256 shareBalance = optShare.balanceOf(withdrawer);
        _changePrank(withdrawer);
        optShare.transferAndCall(address(optChildPeer), shareBalance, "");

        /// @dev Route: OPT -> BASE (WithdrawToParent, parent is the strategy)
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev Route: BASE -> OPT (WithdrawPingPong emitted because adapter is 0)
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev Now set adapter on BASE parent so the next attempt succeeds
        _selectFork(baseFork);
        stdstore.target(address(baseParentPeer)).sig("getActiveStrategyAdapter()")
            .checked_write(address(baseAaveV3Adapter));

        /// @dev Route: OPT -> BASE (WithdrawPingPong retry, parent should complete withdraw)
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev Route: BASE -> OPT (WithdrawCallback with bridged USDC back to withdrawer)
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        /// @dev assert: Withdraw should be completed on OPT child
        _selectFork(optFork);
        assertEq(optShare.balanceOf(withdrawer), 0);
        uint256 fee = _getFee(DEPOSIT_AMOUNT);
        uint256 expectedUsdc = DEPOSIT_AMOUNT - fee;
        assertApproxEqAbs(
            optUsdc.balanceOf(withdrawer), expectedUsdc, BALANCE_TOLERANCE, "USDC should be returned to withdrawer"
        );
    }


    /// @notice Test: Deposit ping-pong when adapter is 0
    /// @notice Flow: Child deposit -> Parent (strategy but adapter=0) -> Ping-pong back
    /// @notice The key is that when strategy is on parent and adapter is 0, parent ping-pongs
    function test_yield_parent_handleCCIPDepositToParent_pingPongWhenAdapterZero() public {
        /// @dev arrange: Strategy on parent, but adapter is 0 (rebalance in transit)
        /// @dev First set strategy normally, then manually set adapter to 0
        _setStrategy(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));
        _selectFork(baseFork);

        /// @dev Now manually set adapter to 0 to simulate rebalance in transit
        stdstore.target(address(baseParentPeer)).sig("getActiveStrategyAdapter()").checked_write(address(0));

        /// @dev Verify adapter is 0
        assertEq(baseParentPeer.getActiveStrategyAdapter(), address(0), "Adapter should be 0");

        /// @dev arrange: Setup deposit on OPT child
        _selectFork(optFork);
        deal(address(optUsdc), depositor, DEPOSIT_AMOUNT);
        _changePrank(depositor);
        optUsdc.approve(address(optChildPeer), DEPOSIT_AMOUNT);

        uint256 fee = _getFee(DEPOSIT_AMOUNT);
        uint256 userPrincipal = DEPOSIT_AMOUNT - fee;

        /// @dev act: Deposit on OPT child
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev Route: OPT -> Parent (DepositToParent)
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);

        /// @dev Route: Parent -> OPT (DepositPingPong) - adapter is 0
        /// @dev This should trigger the ping-pong branch in _handleCCIPDepositToParent (lines 294-295)
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        /// @dev Now set adapter and route again
        _selectFork(baseFork);
        stdstore.target(address(baseParentPeer)).sig("getActiveStrategyAdapter()")
            .checked_write(address(baseAaveV3Adapter));

        /// @dev Route: OPT -> Parent (DepositToParent again)
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);

        /// @dev When strategy is on BASE and adapter is set, parent handles deposit locally
        /// @dev Parent deposits to strategy and sends DepositCallbackChild to OPT
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert: Shares should be minted on OPT child
        _selectFork(optFork);
        uint256 expectedShareMintAmount = userPrincipal * INITIAL_SHARE_PRECISION;
        assertEq(optShare.totalSupply(), expectedShareMintAmount);
        assertEq(optShare.balanceOf(depositor), expectedShareMintAmount);
    }

    /// @notice Test: Withdraw ping-pong when parent IS strategy and adapter is still 0
    /// @notice Flow: Child withdraw -> Parent (strategy, adapter=0) -> Ping-pong -> Child -> Parent (strategy, adapter still 0) -> Ping-pong again
    function test_yield_parent_handleCCIPWithdrawPingPong_parentIsStrategy_adapterStillZero() public {
        /// @dev arrange: Strategy on parent, deposit on OPT child
        _setStrategy(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));

        /// @dev arrange: Deposit on OPT child
        _selectFork(optFork);
        deal(address(optUsdc), depositor, DEPOSIT_AMOUNT);
        _changePrank(depositor);
        optUsdc.approve(address(optChildPeer), DEPOSIT_AMOUNT);
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev Complete deposit flow: OPT -> Parent -> Parent (strategy on parent)
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev arrange: Set adapter to 0 on parent
        _selectFork(baseFork);
        stdstore.target(address(baseParentPeer)).sig("getActiveStrategyAdapter()").checked_write(address(0));

        /// @dev arrange: Withdraw on OPT child
        _selectFork(optFork);
        uint256 shareBalance = optShare.balanceOf(depositor);
        _changePrank(depositor);
        optShare.transferAndCall(address(optChildPeer), shareBalance, "");

        /// @dev Route: OPT -> Parent (WithdrawToParent)
        /// @dev Parent is strategy but adapter is 0, so it ping-pongs back
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev Route: Parent -> OPT (WithdrawPingPong) - adapter is 0
        _selectFork(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev Route: OPT -> Parent (WithdrawPingPong again)
        /// @dev This triggers _handleCCIPWithdrawPingPong -> _handleCCIPWithdraw
        _selectFork(optFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev Route: Parent -> OPT (WithdrawPingPong again) - no USDC, just message
        _selectFork(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev Now set adapter on parent
        _selectFork(baseFork);
        stdstore.target(address(baseParentPeer)).sig("getActiveStrategyAdapter()")
            .checked_write(address(baseAaveV3Adapter));

        /// @dev Route: OPT -> Parent (WithdrawPingPong again, now adapter is set)
        /// @dev This triggers _handleCCIPWithdrawPingPong -> _handleCCIPWithdraw
        /// @dev Parent IS strategy, adapter != 0, withdrawData.chainSelector == OPT
        _selectFork(optFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev Route: Parent -> OPT (WithdrawCallback with USDC)
        _selectFork(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        /// @dev assert: Withdraw should be completed
        _selectFork(optFork);
        assertEq(optShare.balanceOf(depositor), 0);
        uint256 fee = _getFee(DEPOSIT_AMOUNT);
        uint256 expectedUsdc = DEPOSIT_AMOUNT - fee;
        assertApproxEqAbs(
            optUsdc.balanceOf(depositor), expectedUsdc, BALANCE_TOLERANCE, "USDC should be returned to withdrawer"
        );
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
