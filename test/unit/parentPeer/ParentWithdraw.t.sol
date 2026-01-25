// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, console2} from "../../BaseTest.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IComet} from "../../../src/interfaces/IComet.sol";
import {IYieldPeer} from "../../../src/interfaces/IYieldPeer.sol";
import {Roles} from "../../../src/libraries/Roles.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

contract ParentWithdrawTest is BaseTest {
    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();

        /// @dev an initial rate is set in the YieldFees constructor, so rather than accounting for fee in these tests, we set the fee rate to 0
        _setFeeRate(0);

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

    function test_yield_parent_onTokenTransfer_revertsWhen_parentPaused() public {
        _changePrank(emergencyPauser);
        baseParentPeer.emergencyPause();
        _changePrank(depositor);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        baseParentPeer.onTokenTransfer(msg.sender, DEPOSIT_AMOUNT, "");
    }

    /// @notice Scenario: Withdraw made on Parent chain, where the Strategy is, and the Strategy Protocol is Aave
    function test_yield_parent_withdraw_strategyIsParent_aave_withdrawToLocalChain() public {
        /// @dev arrange
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev sanity checks
        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.balanceOf(withdrawer), expectedShareBalance);
        address aUsdc = _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseAaveV3Adapter)),
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
    function test_yield_parent_withdraw_strategyIsParent_compound_withdrawToLocalChain() public {
        _setStrategy(baseChainSelector, keccak256(abi.encodePacked("compound-v3")), SET_CROSS_CHAIN);
        _changePrank(withdrawer);

        /// @dev arrange
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev sanity checks
        uint256 expectedShareBalance = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.balanceOf(withdrawer), expectedShareBalance);
        assertApproxEqAbs(
            IComet(baseNetworkConfig.protocols.comet).balanceOf(address(baseCompoundV3Adapter)),
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
        _setStrategy(optChainSelector, keccak256(abi.encodePacked("aave-v3")), SET_CROSS_CHAIN);
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
        _setStrategy(optChainSelector, keccak256(abi.encodePacked("compound-v3")), SET_CROSS_CHAIN);
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

    /// @notice Withdraw Scenario: Withdraw on Parent, TVL in transit
    function test_yield_parent_withdraw_revertsWhen_strategyPointsToParent_butActiveAdapterIsZero() public {
        /// @dev Arrange: Strategy is on parent with Aave and make a deposit first
        _changePrank(withdrawer);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        /// @dev Get shares
        uint256 shareBalance = baseShare.balanceOf(withdrawer);
        assertGt(shareBalance, 0, "Shares should be minted");

        /// @dev Simulate the rebalance window: manually set activeStrategyAdapter to 0
        stdstore.target(address(baseParentPeer)).sig("getActiveStrategyAdapter()").checked_write(address(0));

        /// @dev Verify activeStrategyAdapter is now 0
        assertEq(baseParentPeer.getActiveStrategyAdapter(), address(0), "ActiveStrategyAdapter should be 0");

        /// @dev Act: Attempt to withdraw
        /// @dev This should revert with ParentPeer__InactiveStrategyAdapter()
        vm.expectRevert(abi.encodeWithSignature("ParentPeer__InactiveStrategyAdapter()"));
        baseShare.transferAndCall(address(baseParentPeer), shareBalance, "");

        /// @dev Assert: Shares should not be burned (withdraw should revert)
        assertEq(baseShare.balanceOf(withdrawer), shareBalance, "Shares should not be burned");
    }

    // ----------------------------------------------------------//
    function test_onTokenTransfer_revertsWhen_zeroAmount() public {
        _changePrank(address(baseShare));
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__NoZeroAmount()"));
        baseParentPeer.onTokenTransfer(withdrawer, 0, "");
    }
}
