// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IComet} from "../../../src/interfaces/IComet.sol";
import {IYieldPeer} from "../../../src/interfaces/IYieldPeer.sol";

contract ParentWithdrawTest is BaseTest {
    function setUp() public override {
        super.setUp();
        /// @dev arbFork is the parent chain
        _selectFork(arbFork);
        deal(address(arbUsdc), withdrawer, DEPOSIT_AMOUNT);
        _changePrank(withdrawer);
        arbUsdc.approve(address(arbParentPeer), DEPOSIT_AMOUNT);
    }

    function test_yield_parent_onTokenTransfer_revertsWhen_notShare() public {
        /// @dev arrange
        arbParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev act and assert
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__OnlyShare()"));
        arbParentPeer.onTokenTransfer(msg.sender, DEPOSIT_AMOUNT, "");
    }

    /// @notice Scenario: Withdraw made on Parent chain, where the Strategy is, and the Strategy Protocol is Aave
    function test_yield_parent_withdraw_strategyIsParent_aave() public {
        /// @dev arrange
        arbParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev sanity checks
        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(arbShare.balanceOf(withdrawer), expectedShareBalance);
        address aUsdc = _getATokenAddress(arbNetworkConfig.aavePoolAddressesProvider, address(arbUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(arbParentPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );

        /// @dev act
        arbShare.transferAndCall(address(arbParentPeer), expectedShareBalance, "");

        /// @dev assert
        assertEq(arbShare.balanceOf(withdrawer), 0);
        assertEq(arbShare.totalSupply(), 0);
        assertApproxEqAbs(
            arbUsdc.balanceOf(withdrawer),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Withdraw made on Parent chain, where the Strategy is, and the Strategy Protocol is Compound
    function test_yield_parent_withdraw_strategyIsParent_compound() public {
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        arbParentPeer.setStrategy(arbChainSelector, IYieldPeer.Protocol.Compound);

        /// @dev arrange
        arbParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev sanity checks
        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(arbShare.balanceOf(withdrawer), expectedShareBalance);
        assertApproxEqAbs(
            IComet(arbNetworkConfig.comet).balanceOf(address(arbParentPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );

        /// @dev act
        arbShare.transferAndCall(address(arbParentPeer), expectedShareBalance, "");

        /// @dev assert
        assertEq(arbShare.balanceOf(withdrawer), 0);
        assertEq(arbShare.totalSupply(), 0);
        assertApproxEqAbs(
            arbUsdc.balanceOf(withdrawer),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Withdraw made on Parent chain, where the Strategy is not, and the Strategy Protocol is Aave
    function test_yield_parent_withdraw_strategyIsNotParent_aave() public {
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        _selectFork(optFork);
        optChildPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(arbFork);
        arbParentPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);

        /// @dev arrange
        arbParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev switch to child chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);
        /// @dev switch back to parent chain and route ccip message with totalValue to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);

        /// @dev sanity checks
        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(arbShare.balanceOf(withdrawer), expectedShareBalance);

        /// @dev act
        arbShare.transferAndCall(address(arbParentPeer), expectedShareBalance, "");
        /// @dev switch to child chain with strategy and route ccip message with totalShares and shareBurnAmount to calculate and get usdcWithdrawAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);
        /// @dev switch back to parent chain and route ccip message with USDC to transfer to withdrawer
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(arbFork, attesters, attesterPks);

        /// @dev assert
        assertEq(arbShare.balanceOf(withdrawer), 0);
        assertEq(arbShare.totalSupply(), 0);
        assertApproxEqAbs(
            arbUsdc.balanceOf(withdrawer),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Withdraw made on Parent chain, where the Strategy is not, and the Strategy Protocol is Compound
    function test_yield_parent_withdraw_strategyIsNotParent_compound() public {
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        _selectFork(optFork);
        optChildPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(arbFork);
        arbParentPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Compound);

        /// @dev arrange
        arbParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev switch to child chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);
        /// @dev switch back to parent chain and route ccip message with totalValue to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);

        /// @dev sanity checks
        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(arbShare.balanceOf(withdrawer), expectedShareBalance);

        /// @dev act
        arbShare.transferAndCall(address(arbParentPeer), expectedShareBalance, "");
        /// @dev switch to child chain with strategy and route ccip message with totalShares and shareBurnAmount to calculate and get usdcWithdrawAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);
        /// @dev switch back to parent chain and route ccip message with USDC to transfer to withdrawer
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(arbFork, attesters, attesterPks);

        /// @dev assert
        assertEq(arbShare.balanceOf(withdrawer), 0);
        assertEq(arbShare.totalSupply(), 0);
        assertApproxEqAbs(
            arbUsdc.balanceOf(withdrawer),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );
    }
}
