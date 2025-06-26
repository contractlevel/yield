// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, console2} from "../../BaseTest.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IComet} from "../../../src/interfaces/IComet.sol";
import {IYieldPeer} from "../../../src/interfaces/IYieldPeer.sol";

contract ParentWithdrawTest is BaseTest {
    function setUp() public override {
        super.setUp();
        /// @dev baseFork is the parent chain
        _selectFork(baseFork);
        deal(address(baseUsdc), withdrawer, DEPOSIT_AMOUNT);
        _changePrank(withdrawer);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
    }

    function test_yield_parent_onTokenTransfer_revertsWhen_notShare() public {
        /// @dev arrange
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev act and assert
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__OnlyShare()"));
        baseParentPeer.onTokenTransfer(msg.sender, DEPOSIT_AMOUNT, "");
    }

    /// @notice Scenario: Withdraw made on Parent chain, where the Strategy is, and the Strategy Protocol is Aave
    function test_yield_parent_withdraw_strategyIsParent_aave() public {
        /// @dev arrange
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev sanity checks
        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.balanceOf(withdrawer), expectedShareBalance);
        address aUsdc = _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseParentPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );

        /// @dev act
        baseShare.transferAndCall(address(baseParentPeer), expectedShareBalance, "");

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

    /// @notice Scenario: Withdraw made on Parent chain, where the Strategy is, and the Strategy Protocol is Compound
    function test_yield_parent_withdraw_strategyIsParent_compound() public {
        _setStrategy(baseChainSelector, IYieldPeer.Protocol.Compound);
        _changePrank(withdrawer);

        /// @dev arrange
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev sanity checks
        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.balanceOf(withdrawer), expectedShareBalance);
        assertApproxEqAbs(
            IComet(baseNetworkConfig.protocols.comet).balanceOf(address(baseParentPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );

        /// @dev act
        baseShare.transferAndCall(address(baseParentPeer), expectedShareBalance, "");

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

    /// @notice Scenario: Withdraw made on Parent chain, where the Strategy is not, and the Strategy Protocol is Aave
    function test_yield_parent_withdraw_strategyIsNotParent_aave() public {
        _setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(baseFork);
        _changePrank(withdrawer);

        /// @dev arrange
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev switch to child chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);
        /// @dev switch back to parent chain and route ccip message with totalValue to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev sanity checks
        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.balanceOf(withdrawer), expectedShareBalance);

        /// @dev act
        baseShare.transferAndCall(address(baseParentPeer), expectedShareBalance, "");
        /// @dev switch to child chain with strategy and route ccip message with totalShares and shareBurnAmount to calculate and get usdcWithdrawAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);
        /// @dev switch back to parent chain and route ccip message with USDC to transfer to withdrawer
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);

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

    /// @notice Scenario: Withdraw made on Parent chain, where the Strategy is not, and the Strategy Protocol is Compound
    function test_yield_parent_withdraw_strategyIsNotParent_compound() public {
        _setStrategy(optChainSelector, IYieldPeer.Protocol.Compound);
        _selectFork(baseFork);
        _changePrank(withdrawer);

        /// @dev arrange
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev switch to child chain and route ccip message with USDC to deposit to strategy
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);
        /// @dev switch back to parent chain and route ccip message with totalValue to calculate shareMintAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev sanity checks
        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.balanceOf(withdrawer), expectedShareBalance);

        /// @dev act
        baseShare.transferAndCall(address(baseParentPeer), expectedShareBalance, "");
        /// @dev switch to child chain with strategy and route ccip message with totalShares and shareBurnAmount to calculate and get usdcWithdrawAmount
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);
        /// @dev switch back to parent chain and route ccip message with USDC to transfer to withdrawer
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);

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

    /// @notice Scenario: Withdraw made on Parent chain, where the Strategy is, and the Strategy Protocol is Aave
    /// @notice but the withdrawal is sent to a different chain
    function test_yield_parent_withdraw_strategyIsParent_aave_withdrawToDifferentChain() public {
        /// @dev arrange
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev sanity checks
        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.balanceOf(withdrawer), expectedShareBalance);
        address aUsdc = _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseParentPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );

        bytes memory encodedWithdrawChainSelector = abi.encode(optChainSelector);

        /// @dev act
        baseShare.transferAndCall(address(baseParentPeer), expectedShareBalance, encodedWithdrawChainSelector);
        assertEq(baseShare.balanceOf(withdrawer), 0);
        assertEq(baseShare.totalSupply(), 0);

        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);
        /// @dev assert
        assertApproxEqAbs(
            optUsdc.balanceOf(withdrawer),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "USDC balance should be approximately equal to deposit amount"
        );
    }

    function test_yield_parent_onTokenTransfer_revertsWhen_withdrawChainNotAllowed() public {
        /// @dev arrange
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev sanity checks
        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.balanceOf(withdrawer), expectedShareBalance);

        bytes memory invalidWithdrawChainSelector = abi.encode(1);

        /// @dev act/assert
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__ChainNotAllowed(uint64)", uint64(1)));
        baseShare.transferAndCall(address(baseParentPeer), expectedShareBalance, invalidWithdrawChainSelector);
    }

    //----------------------------------------------------------//
    function test_withdrawIntegrity_multipleUsers() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");

        uint256 halfMax = type(uint256).max / 2;
        deal(address(baseUsdc), 0x6EF6B6176091F94A8aD52C08e571F81598b226A2, halfMax);
        deal(address(baseUsdc), user1, DEPOSIT_AMOUNT);
        deal(address(baseUsdc), user2, DEPOSIT_AMOUNT);
        deal(address(baseUsdc), user3, DEPOSIT_AMOUNT);

        _changePrank(user1);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.balanceOf(user1), expectedShareBalance);
        console2.log("user1 share balance", baseShare.balanceOf(user1));

        _changePrank(user2);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        console2.log("user2 share balance", baseShare.balanceOf(user2));

        _changePrank(user3);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        console2.log("user3 share balance", baseShare.balanceOf(user3));

        uint256 user3ShareBalance = baseShare.balanceOf(user3);

        baseShare.transferAndCall(address(baseParentPeer), user3ShareBalance, "");

        // assertEq(baseUsdc.balanceOf(user3), DEPOSIT_AMOUNT);
        uint256 slippageTolerance = DEPOSIT_AMOUNT * 99 / 100;

        assertApproxEqAbs(
            baseUsdc.balanceOf(user3),
            DEPOSIT_AMOUNT,
            slippageTolerance,
            "USDC balance should be approximately equal to deposit amount"
        );

        address user4 = makeAddr("user4");
        uint256 user4Deposit = DEPOSIT_AMOUNT / 2;
        deal(address(baseUsdc), user4, user4Deposit);
        _changePrank(user4);
        baseUsdc.approve(address(baseParentPeer), user4Deposit);
        baseParentPeer.deposit(user4Deposit);
        console2.log("user4 share balance", baseShare.balanceOf(user4));
    }

    // ----------------------------------------------------------//
    function test_onTokenTransfer_revertsWhen_zeroAmount() public {
        _changePrank(address(baseShare));
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__NoZeroAmount()"));
        baseParentPeer.onTokenTransfer(withdrawer, 0, "");
    }
}
