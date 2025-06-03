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
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(arbFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev act and assert
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__OnlyShare()"));
        optChildPeer.onTokenTransfer(msg.sender, DEPOSIT_AMOUNT, "");
    }

    // Scenario: Strategy is on the same chain as the child the withdrawal was initiated. Strategy is Aave.
    function test_yield_child_withdraw_strategyIsChild_aave() public {
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        _selectFork(arbFork);
        arbParentPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(optFork);
        optChildPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);

        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        /// @dev act
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, "");
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);
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
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        _selectFork(arbFork);
        arbParentPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(optFork);
        optChildPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Compound);

        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        /// @dev act
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, "");
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);
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
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        optChildPeer.setStrategy(arbChainSelector, IYieldPeer.Protocol.Aave);

        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(arbFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        /// @dev act
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, "");
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);
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
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        _selectFork(arbFork);
        arbParentPeer.setStrategy(arbChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(optFork);
        optChildPeer.setStrategy(arbChainSelector, IYieldPeer.Protocol.Compound);

        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(arbFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        /// @dev act
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, "");
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);
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
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        _selectFork(ethFork);
        ethChildPeer.setStrategy(ethChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(arbFork);
        arbParentPeer.setStrategy(ethChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(optFork);
        optChildPeer.setStrategy(ethChainSelector, IYieldPeer.Protocol.Aave);

        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(arbFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(ethFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        /// @dev act
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, "");
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);
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
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        _selectFork(ethFork);
        ethChildPeer.setStrategy(ethChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(arbFork);
        arbParentPeer.setStrategy(ethChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(optFork);
        optChildPeer.setStrategy(ethChainSelector, IYieldPeer.Protocol.Compound);

        /// @dev arrange
        optChildPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(arbFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(ethFork, attesters, attesterPks);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        /// @dev act
        optShare.transferAndCall(address(optChildPeer), expectedShareBalance, "");
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);
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
