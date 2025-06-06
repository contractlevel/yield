// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";
import {IYieldPeer} from "../../../src/interfaces/IYieldPeer.sol";
import {console2} from "forge-std/Test.sol";

contract ChildWithdrawTest is BaseTest {
    function setUp() public override {
        super.setUp();
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

    // Scenario: Strategy is on the same chain as the child the withdrawal was initiated. Strategy is Aave.
    function test_yield_child_withdraw_strategyIsChild_aave() public {
        _setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);
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
        _setStrategy(optChainSelector, IYieldPeer.Protocol.Compound);
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
        _setStrategy(baseChainSelector, IYieldPeer.Protocol.Aave);
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
        _setStrategy(baseChainSelector, IYieldPeer.Protocol.Compound);
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
        _setStrategy(ethChainSelector, IYieldPeer.Protocol.Aave);
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
        _setStrategy(ethChainSelector, IYieldPeer.Protocol.Compound);
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

    // Scenario: Strategy is on the same chain as the child the withdrawal was initiated. Strategy is Aave.
    // Withdraw chain selector is a different chain
    function test_yield_child_withdraw_strategyIsChild_aave_withdrawToDifferentChain() public {
        _setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(optFork);
        _changePrank(withdrawer);

        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        bytes memory encodedWithdrawChainSelector = abi.encode(baseChainSelector);

        /// @dev act
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, encodedWithdrawChainSelector);
        assertEq(optShare.balanceOf(withdrawer), 0);
        assertEq(optShare.totalSupply(), 0);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);

        /// @dev assert
        assertApproxEqAbs(
            baseUsdc.balanceOf(withdrawer),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );
    }

    function test_yield_child_onTokenTransfer_revertsWhen_withdrawChainNotAllowed() public {
        _setStrategy(optChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(optFork);
        _changePrank(withdrawer);

        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev sanity checks
        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(optShare.balanceOf(withdrawer), expectedShareBalance);

        bytes memory invalidWithdrawChainSelector = abi.encode(1);

        /// @dev act/assert
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__ChainNotAllowed(uint64)", uint64(1)));
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, invalidWithdrawChainSelector);
    }
}
