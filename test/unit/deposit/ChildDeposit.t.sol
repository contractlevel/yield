// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IERC20} from "../../BaseTest.t.sol";
import {IYieldPeer} from "../../../src/interfaces/IYieldPeer.sol";
import {IComet} from "../../../src/interfaces/IComet.sol";

contract ChildDepositTest is BaseTest {
    function setUp() public override {
        super.setUp();
        /// @dev optFork is a child chain
        _selectFork(optFork);
        deal(address(optUsdc), depositor, DEPOSIT_AMOUNT);
        _changePrank(depositor);
        optUsdc.approve(address(optChildPeer), DEPOSIT_AMOUNT);
    }

    function test_yield_child_deposit_revertsWhen_zeroAmount() public {
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__NoZeroAmount()"));
        optChildPeer.deposit(0);
    }

    // - child/deposit is strategy
    //     - deposit usdc directly into this-child-strategy
    //     - ccipMessage to parent, passing amount deposited and `totalValue`
    //     - ccipReceive from parent, getting shareMintAmount
    function test_yield_child_deposit_strategyIsChild_aave() public {
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        optChildPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);

        uint256 usdcBalanceBefore = optUsdc.balanceOf(depositor);

        /// @dev act
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = optUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev assert USDC was deposited to Aave
        address aUsdc = _getATokenAddress(optNetworkConfig.aavePoolAddressesProvider, address(optUsdc));
        assertEq(IERC20(aUsdc).balanceOf(address(optChildPeer)), DEPOSIT_AMOUNT);

        /// @dev switch to parent chain and route ccip message with totalValue and amount deposited to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(arbParentPeer.getTotalShares(), expectedShareMintAmount);

        /// @dev switch back to child chain and route ccip message with shareMintAmount to mint shares
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert correct amount of shares minted
        assertEq(optShare.totalSupply(), expectedShareMintAmount);
        assertEq(optShare.balanceOf(depositor), expectedShareMintAmount);
    }

    function test_yield_child_deposit_strategyIsChild_compound() public {
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        optChildPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Compound);

        uint256 usdcBalanceBefore = optUsdc.balanceOf(depositor);

        /// @dev act
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = optUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev assert USDC was deposited to Compound
        uint256 compoundBalance = IComet(optNetworkConfig.comet).balanceOf(address(optChildPeer));
        assertApproxEqAbs(
            compoundBalance,
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );

        /// @dev switch to parent chain and route ccip message with totalValue and amount deposited to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(arbParentPeer.getTotalShares(), expectedShareMintAmount);

        /// @dev switch back to child chain and route ccip message with shareMintAmount to mint shares
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert correct amount of shares minted
        assertEq(optShare.totalSupply(), expectedShareMintAmount);
        assertEq(optShare.balanceOf(depositor), expectedShareMintAmount);
    }

    // - parent is strategy
    //     - send usdc and depositData from child to parent strategy
    //     - deposit usdc directly into parent strategy
    //     - calculate and send `shareMintAmount` from parent-strategy to child
    function test_yield_child_deposit_strategyIsParent_aave() public {
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        _selectFork(optFork);
        optChildPeer.setStrategy(arbChainSelector, IYieldPeer.Protocol.Aave);

        uint256 usdcBalanceBefore = optUsdc.balanceOf(depositor);

        /// @dev act
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = optUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev switch to parent chain and route ccip message with USDC to deposit to strategy
        /// and calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(arbFork, attesters, attesterPks);

        /// @dev assert USDC was deposited to Aave
        address aUsdc = _getATokenAddress(arbNetworkConfig.aavePoolAddressesProvider, address(arbUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(arbParentPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );

        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(arbParentPeer.getTotalShares(), expectedShareMintAmount);

        /// @dev switch back to child chain and route ccip message with shareMintAmount to mint shares
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert correct amount of shares minted
        assertEq(optShare.totalSupply(), expectedShareMintAmount);
        assertEq(optShare.balanceOf(depositor), expectedShareMintAmount);
    }

    function test_yield_child_deposit_strategyIsParent_compound() public {
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        _selectFork(arbFork);
        arbParentPeer.setStrategy(arbChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(optFork);
        optChildPeer.setStrategy(arbChainSelector, IYieldPeer.Protocol.Compound);

        uint256 usdcBalanceBefore = optUsdc.balanceOf(depositor);

        /// @dev act
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = optUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev switch to parent chain and route ccip message with USDC to deposit to strategy
        /// and calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(arbFork, attesters, attesterPks);

        /// @dev assert USDC was deposited to Compound
        uint256 compoundBalance = IComet(arbNetworkConfig.comet).balanceOf(address(arbParentPeer));
        assertApproxEqAbs(
            compoundBalance,
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );

        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(arbParentPeer.getTotalShares(), expectedShareMintAmount);

        /// @dev switch back to child chain and route ccip message with shareMintAmount to mint shares
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert correct amount of shares minted
        assertEq(optShare.totalSupply(), expectedShareMintAmount);
        assertEq(optShare.balanceOf(depositor), expectedShareMintAmount);
    }

    // - chain c is strategy
    //     - send usdc and depositData from child to parent
    //     - send usdc and depositData from parent to strategy (and deposit in strategy)
    //     - send `totalValue` and depositData from strategy to parent
    //     - send `shareMintAmount` from parent to child
    function test_yield_child_deposit_strategyIsChainC_aave() public {
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        _selectFork(ethFork);
        ethChildPeer.setStrategy(ethChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(arbFork);
        arbParentPeer.setStrategy(ethChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(optFork);
        optChildPeer.setStrategy(ethChainSelector, IYieldPeer.Protocol.Aave);

        uint256 usdcBalanceBefore = optUsdc.balanceOf(depositor);

        /// @dev act
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = optUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev switch to parent chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(arbFork, attesters, attesterPks);
        /// @dev switch to third chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(ethFork, attesters, attesterPks);

        /// @dev assert USDC was deposited to Aave
        address aUsdc = _getATokenAddress(ethNetworkConfig.aavePoolAddressesProvider, address(ethUsdc));
        assertEq(IERC20(aUsdc).balanceOf(address(ethChildPeer)), DEPOSIT_AMOUNT);

        /// @dev switch to parent chain and route ccip message with totalValue and amount deposited to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(arbParentPeer.getTotalShares(), expectedShareMintAmount);

        /// @dev switch back to deposit child chain and route ccip message with shareMintAmount to mint shares
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert correct amount of shares minted
        assertEq(optShare.totalSupply(), expectedShareMintAmount);
        assertEq(optShare.balanceOf(depositor), expectedShareMintAmount);
    }

    function test_yield_child_deposit_strategyIsChainC_compound() public {
        // @review REPLACE THIS WITH A WRAPPER OR ACTUAL CLF CALLTRACE
        _selectFork(ethFork);
        ethChildPeer.setStrategy(ethChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(arbFork);
        arbParentPeer.setStrategy(ethChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(optFork);
        optChildPeer.setStrategy(ethChainSelector, IYieldPeer.Protocol.Compound);

        uint256 usdcBalanceBefore = optUsdc.balanceOf(depositor);

        /// @dev act
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = optUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev switch to parent chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(arbFork, attesters, attesterPks);
        /// @dev switch to third chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(ethFork, attesters, attesterPks);

        /// @dev assert USDC was deposited to Compound
        uint256 compoundBalance = IComet(ethNetworkConfig.comet).balanceOf(address(ethChildPeer));
        assertApproxEqAbs(
            compoundBalance,
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );

        /// @dev switch to parent chain and route ccip message with totalValue and amount deposited to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(arbFork);
        /// @dev assert total shares is the expected amount
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(arbParentPeer.getTotalShares(), expectedShareMintAmount);

        /// @dev switch back to deposit child chain and route ccip message with shareMintAmount to mint shares
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert correct amount of shares minted
        assertEq(optShare.totalSupply(), expectedShareMintAmount);
        assertEq(optShare.balanceOf(depositor), expectedShareMintAmount);
    }
}
