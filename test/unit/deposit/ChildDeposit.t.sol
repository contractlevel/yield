// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IERC20} from "../../BaseTest.t.sol";
import {IYieldPeer} from "../../../src/interfaces/IYieldPeer.sol";
import {IComet} from "../../../src/interfaces/IComet.sol";
import {console2} from "forge-std/console2.sol";

contract ChildDepositTest is BaseTest {
    function setUp() public override {
        super.setUp();
        /// @dev optFork is a child chain
        _selectFork(optFork);
        deal(address(optUsdc), depositor, DEPOSIT_AMOUNT);
        _changePrank(depositor);
        optUsdc.approve(address(optChildPeer), DEPOSIT_AMOUNT);
    }

    function test_yield_child_deposit_revertsWhen_insufficientAmount() public {
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__InsufficientAmount()"));
        optChildPeer.deposit(1e6 - 1);
    }

    // - child/deposit is strategy
    //     - deposit usdc directly into this-child-strategy
    //     - ccipMessage to parent, passing amount deposited and `totalValue`
    //     - ccipReceive from parent, getting shareMintAmount
    function test_yield_child_deposit_strategyIsChild_aave() public {
        /// @dev arrange
        _setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(optFork);
        _changePrank(depositor);

        uint256 usdcBalanceBefore = optUsdc.balanceOf(depositor);

        /// @dev act
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = optUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev assert USDC was deposited to Aave
        address aUsdc = _getATokenAddress(optNetworkConfig.protocols.aavePoolAddressesProvider, address(optUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(optChildPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );

        /// @dev switch to parent chain and route ccip message with totalValue and amount deposited to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);

        /// @dev switch back to child chain and route ccip message with shareMintAmount to mint shares
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert correct amount of shares minted
        assertEq(optShare.totalSupply(), expectedShareMintAmount);
        assertEq(optShare.balanceOf(depositor), expectedShareMintAmount);
    }

    function test_yield_child_deposit_strategyIsChild_compound() public {
        /// @dev arrange
        _setStrategy(optChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(optFork);
        _changePrank(depositor);

        uint256 usdcBalanceBefore = optUsdc.balanceOf(depositor);

        /// @dev act
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = optUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev assert USDC was deposited to Compound
        uint256 compoundBalance = IComet(optNetworkConfig.protocols.comet).balanceOf(address(optChildPeer));
        assertApproxEqAbs(
            compoundBalance,
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );

        /// @dev switch to parent chain and route ccip message with totalValue and amount deposited to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);

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
        uint256 usdcBalanceBefore = optUsdc.balanceOf(depositor);

        /// @dev act
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = optUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev switch to parent chain and route ccip message with USDC to deposit to strategy
        /// and calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);

        /// @dev assert USDC was deposited to Aave
        address aUsdc = _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseParentPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );

        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);

        /// @dev switch back to child chain and route ccip message with shareMintAmount to mint shares
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert correct amount of shares minted
        assertEq(optShare.totalSupply(), expectedShareMintAmount);
        assertEq(optShare.balanceOf(depositor), expectedShareMintAmount);
    }

    function test_yield_child_deposit_strategyIsParent_compound() public {
        /// @dev arrange
        _setStrategy(baseChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(optFork);
        _changePrank(depositor);

        uint256 usdcBalanceBefore = optUsdc.balanceOf(depositor);

        /// @dev act
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = optUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev switch to parent chain and route ccip message with USDC to deposit to strategy
        /// and calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);

        /// @dev assert USDC was deposited to Compound
        uint256 compoundBalance = IComet(baseNetworkConfig.protocols.comet).balanceOf(address(baseParentPeer));
        assertApproxEqAbs(
            compoundBalance,
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );

        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);

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
        /// @dev arrange
        _setStrategy(ethChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(optFork);
        _changePrank(depositor);

        uint256 usdcBalanceBefore = optUsdc.balanceOf(depositor);

        /// @dev act
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = optUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev switch to parent chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
        /// @dev switch to third chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(ethFork, attesters, attesterPks);

        /// @dev assert USDC was deposited to Aave
        address aUsdc = _getATokenAddress(ethNetworkConfig.protocols.aavePoolAddressesProvider, address(ethUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(ethChildPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );

        /// @dev switch to parent chain and route ccip message with totalValue and amount deposited to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);

        /// @dev switch back to deposit child chain and route ccip message with shareMintAmount to mint shares
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert correct amount of shares minted
        assertEq(optShare.totalSupply(), expectedShareMintAmount);
        assertEq(optShare.balanceOf(depositor), expectedShareMintAmount);
    }

    function test_yield_child_deposit_strategyIsChainC_compound() public {
        /// @dev arrange
        _setStrategy(ethChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(optFork);
        _changePrank(depositor);

        uint256 usdcBalanceBefore = optUsdc.balanceOf(depositor);

        /// @dev act
        optChildPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev assert depositor's USDC balance reduced by the deposit amount
        uint256 usdcBalanceAfter = optUsdc.balanceOf(depositor);
        assertEq(usdcBalanceAfter, usdcBalanceBefore - DEPOSIT_AMOUNT);

        /// @dev switch to parent chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);
        /// @dev switch to third chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(ethFork, attesters, attesterPks);

        /// @dev assert USDC was deposited to Compound
        uint256 compoundBalance = IComet(ethNetworkConfig.protocols.comet).balanceOf(address(ethChildPeer));
        assertApproxEqAbs(
            compoundBalance,
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );

        /// @dev switch to parent chain and route ccip message with totalValue and amount deposited to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);
        /// @dev assert total shares is the expected amount
        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseParentPeer.getTotalShares(), expectedShareMintAmount);

        /// @dev switch back to deposit child chain and route ccip message with shareMintAmount to mint shares
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert correct amount of shares minted
        assertEq(optShare.totalSupply(), expectedShareMintAmount);
        assertEq(optShare.balanceOf(depositor), expectedShareMintAmount);
    }
}
