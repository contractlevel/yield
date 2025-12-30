// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IERC20} from "../../BaseTest.t.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

contract ParentDepositPingPongTest is BaseTest {
    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();

        /// @dev baseFork is the parent chain
        _selectFork(baseFork);
        deal(address(baseUsdc), depositor, DEPOSIT_AMOUNT);

        _changePrank(depositor);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
    }

    /// @notice Test: Deposit ping-pong when adapter is 0
    /// @notice Flow: Child deposit -> Parent (strategy but adapter=0) -> Ping-pong back
    /// @notice The key is that when strategy is on parent and adapter is 0, parent ping-pongs
    function test_yield_parent_handleCCIPDepositToParent_pingPongsWhen_activeStrategyAdapterIsZero() public {
        /// @dev arrange: Strategy on parent, but adapter is 0 (rebalance in transit)
        /// @dev First set strategy normally, then manually set adapter to 0
        _setStrategy(baseChainSelector, keccak256(abi.encodePacked("aave-v3")), NO_CROSS_CHAIN);
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
}
