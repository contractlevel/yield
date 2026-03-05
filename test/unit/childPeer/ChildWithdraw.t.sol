// SPDX-License-Identifier: UNLICENSED
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

    /// @notice Verifies that shares are held by the peer (not burned) immediately after onTokenTransfer in a cross-chain scenario
    /// @notice Phase 1 guarantee: deferred burn - shares are only burned after strategy withdrawal is confirmed
    function test_yield_child_onTokenTransfer_sharesHeldByPeer_notBurned() public {
        /// @dev arrange: deposit and complete CCIP hops to receive shares
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        /// @dev act: initiate withdrawal - do NOT route any CCIP messages
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, "");

        /// @dev assert: shares held by peer, not burned
        assertEq(optShare.balanceOf(withdrawer), 0, "Withdrawer should have no shares");
        assertEq(optShare.balanceOf(address(optChildPeer)), expectedShareBalance, "Peer should hold shares");
        assertEq(optShare.totalSupply(), expectedShareBalance, "Total supply should not have decreased");
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

    /// @notice Scenario C: Child (opt) initiates withdrawal, strategy is on the same child chain (opt), Protocol: Aave
    /// @notice CCIP hops: opt->base (WithdrawToParent), base->opt (WithdrawToStrategy), opt->base (WithdrawCallbackParent), base->opt (WithdrawCallbackChild)
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
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
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

    /// @notice Scenario C: Child (opt) initiates withdrawal, strategy is on the same child chain (opt), Protocol: Compound
    /// @notice CCIP hops: opt->base (WithdrawToParent), base->opt (WithdrawToStrategy), opt->base (WithdrawCallbackParent), base->opt (WithdrawCallbackChild)
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
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
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

    /// @notice Scenario A: Child (opt) initiates withdrawal, strategy is on parent (base), Protocol: Aave
    /// @notice CCIP hops: opt->base (WithdrawToParent), base->opt (WithdrawCallbackChild)
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

    /// @notice Scenario A: Child (opt) initiates withdrawal, strategy is on parent (base), Protocol: Compound
    /// @notice CCIP hops: opt->base (WithdrawToParent), base->opt (WithdrawCallbackChild)
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

    /// @notice Scenario B: Child (opt) initiates withdrawal, strategy is on another child (eth), Protocol: Aave
    /// @notice CCIP hops: opt->base (WithdrawToParent), base->eth (WithdrawToStrategy), eth->base (WithdrawCallbackParent), base->opt (WithdrawCallbackChild)
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
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
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

    /// @notice Scenario B: Child (opt) initiates withdrawal, strategy is on another child (eth), Protocol: Compound
    /// @notice CCIP hops: opt->base (WithdrawToParent), base->eth (WithdrawToStrategy), eth->base (WithdrawCallbackParent), base->opt (WithdrawCallbackChild)
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
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
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
