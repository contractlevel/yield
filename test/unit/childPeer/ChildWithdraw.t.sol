// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";
import {IYieldPeer} from "../../../src/interfaces/IYieldPeer.sol";
import {Roles} from "../../../src/libraries/Roles.sol";
import {console2} from "forge-std/Test.sol";

contract ChildWithdrawTest is BaseTest {
    function setUp() public override {
        super.setUp();

        /// @dev an initial rate is set in the YieldFees constructor, so rather than accounting for fee in these tests, we set the fee rate to 0
        _setFeeRate(0);

        /// @dev optFork is a child chain
        _selectFork(optFork);
        deal(address(optUsdc), withdrawer, DEPOSIT_AMOUNT);
        _changePrank(withdrawer);
        optUsdc.approve(address(optChildPeer), DEPOSIT_AMOUNT);
    }

    function test_yield_child_onTokenTransfer_revertsWhen_notShare() public {
        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev act and assert
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__OnlyShare()"));
        optChildPeer.onTokenTransfer(msg.sender, DEPOSIT_AMOUNT, "");
    }

    function test_yield_child_onTokenTransfer_revertsWhen_paused() public {
        _changePrank(emergencyPauser);
        optChildPeer.pause();
        _changePrank(depositor);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        optChildPeer.onTokenTransfer(msg.sender, DEPOSIT_AMOUNT, "");
    }

    // Scenario: Strategy is on the same chain as the child the withdrawal was initiated. Strategy is Aave.
    function test_yield_child_withdraw_strategyIsChild_aave() public {
        _setStrategy(optChainSelector, keccak256(abi.encodePacked("aave-v3")), SET_CROSS_CHAIN);
        _selectFork(optFork);
        _changePrank(withdrawer);

        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        /// @dev act
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, "");
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert
        assertEq(optShare.balanceOf(withdrawer), 0);
        assertEq(optShare.totalSupply(), 0);
        assertApproxEqAbs(
            optUsdc.balanceOf(withdrawer),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );
    }

    // Scenario: Strategy is on the same chain as the child the withdrawal was initiated. Strategy is Compound.
    function test_yield_child_withdraw_strategyIsChild_compound() public {
        _setStrategy(optChainSelector, keccak256(abi.encodePacked("compound-v3")), SET_CROSS_CHAIN);
        _selectFork(optFork);
        _changePrank(withdrawer);

        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        /// @dev act
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, "");
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert
        assertEq(optShare.balanceOf(withdrawer), 0);
        assertEq(optShare.totalSupply(), 0);
        assertApproxEqAbs(
            optUsdc.balanceOf(withdrawer),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Withdrawal is initiated from a child chain, Strategy chain is Parent chain, Strategy Protocol is Aave.
    function test_yield_child_withdraw_strategyIsParent_aave() public {
        _selectFork(optFork);
        _changePrank(withdrawer);

        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        /// @dev act
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, "");
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        /// @dev assert
        assertEq(optShare.balanceOf(withdrawer), 0);
        assertEq(optShare.totalSupply(), 0);
        assertApproxEqAbs(
            optUsdc.balanceOf(withdrawer),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Withdrawal is initiated from a child chain, Strategy chain is Parent chain, Strategy Protocol is Compound.
    function test_yield_child_withdraw_strategyIsParent_compound() public {
        _setStrategy(baseChainSelector, keccak256(abi.encodePacked("compound-v3")), SET_CROSS_CHAIN);
        _selectFork(optFork);
        _changePrank(withdrawer);

        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        /// @dev act
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, "");
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        /// @dev assert
        assertEq(optShare.balanceOf(withdrawer), 0);
        assertEq(optShare.totalSupply(), 0);
        assertApproxEqAbs(
            optUsdc.balanceOf(withdrawer),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Withdrawal is initiated from a child chain, Strategy chain is another child chain, Strategy Protocol is Aave.
    function test_yield_child_withdraw_strategyIsChainC_aave() public {
        _setStrategy(ethChainSelector, keccak256(abi.encodePacked("aave-v3")), SET_CROSS_CHAIN);
        _selectFork(optFork);
        _changePrank(withdrawer);

        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(ethFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        /// @dev act
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, "");
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(ethFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        /// @dev assert
        assertEq(optShare.balanceOf(withdrawer), 0);
        assertEq(optShare.totalSupply(), 0);
        assertApproxEqAbs(
            optUsdc.balanceOf(withdrawer),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Withdrawal is initiated from a child chain, Strategy chain is another child chain, Strategy Protocol is Compound.
    function test_yield_child_withdraw_strategyIsChainC_compound() public {
        _setStrategy(ethChainSelector, keccak256(abi.encodePacked("compound-v3")), SET_CROSS_CHAIN);
        _selectFork(optFork);
        _changePrank(withdrawer);

        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(ethFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        /// @dev act
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, "");
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(ethFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        /// @dev assert
        assertEq(optShare.balanceOf(withdrawer), 0);
        assertEq(optShare.totalSupply(), 0);
        assertApproxEqAbs(
            optUsdc.balanceOf(withdrawer),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );
    }
}
