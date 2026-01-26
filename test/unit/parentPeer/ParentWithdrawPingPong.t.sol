// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IERC20} from "../../BaseTest.t.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

contract ParentWithdrawPingPongTest is BaseTest {
    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();

        /// @dev we start on child to test pingpong handling on the parent chain
        _selectFork(optFork);
        deal(address(optUsdc), withdrawer, DEPOSIT_AMOUNT);
        _changePrank(withdrawer);
        optUsdc.approve(address(optChildPeer), DEPOSIT_AMOUNT);
    }

    /// @notice Test: Withdraw ping-pong when parent is strategy but adapter is 0
    /// @notice Flow: Withdraw on child -> Parent is strategy (adapter=0) -> Parent ping-pongs -> Child retries
    /// @notice The ping-pong happens inside _handleCCIPWithdraw on the parent
    function test_yield_parent_handleCCIPWithdraw_pingPongsWhen_activeStrategyAdapterIsZero() public {
        /// @dev arrange: Strategy on BASE parent, deposit on OPT child so shares live on child chain
        _selectFork(optFork);
        _changePrank(withdrawer);
        optChildPeer.deposit(USDC_ID, DEPOSIT_AMOUNT);

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

    /// @notice Test: Withdraw ping-pong when parent IS strategy and adapter is still 0
    /// @notice Flow: Child withdraw -> Parent (strategy, adapter=0) -> Ping-pong -> Child -> Parent (strategy, adapter still 0) -> Ping-pong again
    function test_yield_parent_handleCCIPWithdrawPingPong_multiplePingPongsWhen_activeStrategyAdapterIsZero() public {
        /// @dev arrange: Deposit on OPT child
        _selectFork(optFork);
        _changePrank(withdrawer);
        optChildPeer.deposit(USDC_ID, DEPOSIT_AMOUNT);

        /// @dev Complete deposit flow: OPT -> Parent -> Parent (strategy on parent)
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev arrange: Set adapter to 0 on parent
        _selectFork(baseFork);
        stdstore.target(address(baseParentPeer)).sig("getActiveStrategyAdapter()").checked_write(address(0));

        /// @dev arrange: Withdraw on OPT child
        _selectFork(optFork);
        uint256 shareBalance = optShare.balanceOf(withdrawer);
        _changePrank(withdrawer);
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
        assertEq(optShare.balanceOf(withdrawer), 0);
        uint256 fee = _getFee(DEPOSIT_AMOUNT);
        uint256 expectedUsdc = DEPOSIT_AMOUNT - fee;
        assertApproxEqAbs(
            optUsdc.balanceOf(withdrawer), expectedUsdc, BALANCE_TOLERANCE, "USDC should be returned to withdrawer"
        );
    }
}
