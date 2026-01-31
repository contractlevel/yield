// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IERC20} from "../../BaseTest.t.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

contract ChildDepositPingPongTest is BaseTest {
    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        _setFeeRate(INITIAL_FEE_RATE);

        _selectFork(optFork);
        deal(address(optUsdc), depositor, DEPOSIT_AMOUNT);
        _changePrank(depositor);
        optUsdc.approve(address(optChildPeer), DEPOSIT_AMOUNT);
    }

    // Two-chain scenario (Parent and OPT):
    // - Parent strategy points to OPT, but OPT's adapter is 0 initially
    // - Deposit on OPT -> Parent forwards to OPT (attempt 1)
    // - OPT sees adapter == 0, ping-pongs back to Parent
    // - Set OPT adapter, Parent forwards again (attempt 2), deposit succeeds
    function test_yield_child_deposit_pingpong_twoChains_aave() public {
        // Arrange: Set Parent strategy to OPT (Aave)

        {
            _selectFork(baseFork);
            _setStrategy(optChainSelector, keccak256("aave-v3"), NO_CROSS_CHAIN);
        }

        // First sanity check for opt adapter == 0
        _selectFork(optFork);
        assertEq(optChildPeer.getActiveStrategyAdapter(), address(0));

        uint256 fee = _getFee(DEPOSIT_AMOUNT);
        uint256 userPrincipal = DEPOSIT_AMOUNT - fee;
        uint256 optChildUsdcBalanceBefore = optUsdc.balanceOf(address(optChildPeer));

        // Act: Deposit from/on OPT child
        _changePrank(depositor);
        optChildPeer.deposit(USDC_ID, DEPOSIT_AMOUNT);

        // Get initial balance before any routing (sanity check)
        address aUsdcOpt = _getATokenAddress(optNetworkConfig.protocols.aavePoolAddressesProvider, address(optUsdc));
        uint256 optAaveBalanceBeforeAttempt1 = IERC20(aUsdcOpt).balanceOf(address(optAaveV3Adapter));

        // Route OPT -> Parent  (DepositToParent)
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);

        // Parent -> OPT (DepositToStrategy attempt 1)
        // Ensure we're on Base fork before routing (Parent forwards USDC to OPT)
        // Note: Parent should have emitted a CCTP MessageSent event when processing OPT -> Parent
        _selectFork(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        // OPT ping-pongs back to Parent since adapter == 0 (with USDC)
        // OPT should now have the USDC from Parent
        _selectFork(optFork);
        uint256 optUsdcBalanceAfterReceive = optUsdc.balanceOf(address(optChildPeer));
        assertGt(optUsdcBalanceAfterReceive, 0, "OPT should have received USDC from Parent");
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);

        // Assert: No deposit occurred on OPT in attempt 1
        _selectFork(optFork);
        assertEq(
            IERC20(aUsdcOpt).balanceOf(address(optAaveV3Adapter)),
            optAaveBalanceBeforeAttempt1,
            "No deposit should occur before adapter is set"
        );

        // Simulate adapter and stablecoin update on OPT using stdstore
        stdstore.target(address(optChildPeer)).sig("getActiveStrategyAdapter()")
            .checked_write(address(optAaveV3Adapter));
        stdstore.target(address(optChildPeer)).sig("getActiveStablecoin()").checked_write(address(optUsdc));
        assertEq(optChildPeer.getActiveStrategyAdapter(), address(optAaveV3Adapter));
        assertEq(optChildPeer.getActiveStablecoin(), address(optUsdc));

        // Parent -> OPT (attempt 2): deposit should happen now
        // Now this should be a _handleCCIPDepositPingPong from parent, doing a ccipSend to the strategy
        _selectFork(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        // Assert OPT deposit
        uint256 optAaveBalanceAfter = IERC20(aUsdcOpt).balanceOf(address(optAaveV3Adapter));
        assertApproxEqAbs(
            optAaveBalanceAfter,
            optAaveBalanceBeforeAttempt1 + userPrincipal,
            BALANCE_TOLERANCE,
            "OPT Aave balance should increase by userPrincipal"
        );

        //  Strategy (OPT) -> Parent (DepositCallbackParent with totalValue)
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        // parent shareMintAmount, forwards to child to mint shares
        _selectFork(baseFork);
        uint256 expectedShareMintAmount = userPrincipal * INITIAL_SHARE_PRECISION;
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);

        // Parent -> OPT (DepositCallbackChild) and mint shares on OPT
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        // asserts on OPT child
        _selectFork(optFork);
        assertEq(optShare.totalSupply(), expectedShareMintAmount);
        assertEq(optShare.balanceOf(depositor), expectedShareMintAmount);
        assertEq(optUsdc.balanceOf(address(optChildPeer)), optChildUsdcBalanceBefore + fee);
    }
}

