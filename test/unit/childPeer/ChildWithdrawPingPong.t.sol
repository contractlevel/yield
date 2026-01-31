// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IERC20} from "../../BaseTest.t.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";
import {IYieldPeer} from "../../../src/interfaces/IYieldPeer.sol";

contract ChildWithdrawPingPongTest is BaseTest {
    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();

        _setFeeRate(0);

        /// @dev optFork is a child chain
        _selectFork(baseFork);
        deal(address(baseUsdc), withdrawer, DEPOSIT_AMOUNT);
        _changePrank(withdrawer);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
    }

    /// @notice Scenario: Withdrawal is initiated from a child chain, StrategyAdapter == 0 in ChildPeer, Withdrawal is forwarded to Parent, s_strategy on Parent points at Child chain, ping-pongs back to Child chain, Withdrawal ping-pongs back to Parent -> Child, Withdrawal is completed
    function test_yield_child_withdraw_pingpong_twoChains_aave() public {
        /// arrange for initial deposit setup, strategy is on Parent for deposit
        _selectFork(baseFork);
        _changePrank(withdrawer);

        /// @dev arrange
        /// @notice strategy chain selector here is the parent (base)
        baseParentPeer.deposit(USDC_ID, DEPOSIT_AMOUNT);
        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        /// @dev sanity check
        address aUsdc = _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseAaveV3Adapter)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
        /// NOW arrange for Rebalancing
        /// @dev act
        /// @notice here we are setting the strategy chain selector to a child (opt)
        _setStrategy(optChainSelector, keccak256(abi.encodePacked("aave-v3")), NO_CROSS_CHAIN);

        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        /// @dev assert
        address optAaveUsdc = _getATokenAddress(optNetworkConfig.protocols.aavePoolAddressesProvider, address(optUsdc));
        assertApproxEqAbs(
            IERC20(optAaveUsdc).balanceOf(address(optAaveV3Adapter)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );

        /// FINALLY a last arrange just for the strategyAdapter to now show 0 just on optChild
        /// We will undo this after ping ponging
        stdstore.target(address(optChildPeer)).sig("getActiveStrategyAdapter()").checked_write(address(0));
        /// @dev act
        /// lets initiate the withdrawal on baseParent
        _selectFork(baseFork);
        _changePrank(withdrawer);
        baseShare.transferAndCall(address(baseParentPeer), expectedShareBalance, "");
        /// parent should forward to child (strategy chain)
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);
        /// child should pingpong back to parent since adapter is 0
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        /// then we set strategyAdapter and stablecoin on optChild to active
        stdstore.target(address(optChildPeer)).sig("getActiveStrategyAdapter()")
            .checked_write(address(optAaveV3Adapter));
        stdstore.target(address(optChildPeer)).sig("getActiveStablecoin()").checked_write(address(optUsdc));

        /// parent should forward to child again
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);
        /// child should forward USDC back to parent
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
        /// withdrawal on base should be completed

        /// @dev assert
        assertEq(baseShare.balanceOf(withdrawer), 0);
        assertEq(baseShare.totalSupply(), 0);
        assertApproxEqAbs(
            baseUsdc.balanceOf(withdrawer),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );
    }
}
