// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IERC20, Vm, IYieldPeer, IComet} from "../../BaseTest.t.sol";

contract RebalanceTest is BaseTest {
    function setUp() public override {
        super.setUp();

        /// @dev an initial rate is set in the YieldFees constructor, so rather than accounting for fee in these tests, we set the fee rate to 0
        _setFeeRate(0);

        /// @dev baseFork is the parent chain
        _selectFork(baseFork);
        deal(address(baseUsdc), depositor, DEPOSIT_AMOUNT);
        _changePrank(depositor);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
    }

    /// @notice Scenario: New Strategy is same as the old
    function test_yield_parentPeer_rebalance_sameStrategy() public {
        /// @dev arrange
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev sanity check
        address aUsdc = _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseAaveV3Adapter)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );

        vm.recordLogs();

        /// @dev act
        /// @notice the strategy chain and protocol are the same as the old strategy
        _setStrategy(baseChainSelector, keccak256(abi.encodePacked("aave-v3")), SET_CROSS_CHAIN);

        /// @dev assert
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 eventSignature = keccak256("CurrentStrategyOptimal(uint64,bytes32)");
        uint64 emittedChainSelector;
        bytes32 emittedProtocolId;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == eventSignature) {
                emittedChainSelector = uint64(uint256(logs[i].topics[1]));
                emittedProtocolId = logs[i].topics[2];
            }
        }
        assertEq(emittedChainSelector, baseChainSelector);
        assertEq(emittedProtocolId, keccak256(abi.encodePacked("aave-v3")));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseAaveV3Adapter)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Old Strategy and New are both on Parent, but different protocols
    function test_yield_parentPeer_rebalance_oldParent_newParent() public {
        /// @dev arrange
        /// @notice the current/old strategy chain is the parent (base) whereas the protocl is Aave
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev sanity check
        address aUsdc = _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseAaveV3Adapter)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );

        /// @dev act
        /// @notice here we are setting the new strategy chain to the same parent (base) whereas the protocol is Compound
        _setStrategy(baseChainSelector, keccak256(abi.encodePacked("compound-v3")), SET_CROSS_CHAIN);

        /// @dev assert
        assertEq(IERC20(aUsdc).balanceOf(address(baseAaveV3Adapter)), 0);
        uint256 compoundBalance = IComet(baseNetworkConfig.protocols.comet).balanceOf(address(baseCompoundV3Adapter));
        assertApproxEqAbs(
            compoundBalance,
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Old Strategy is on child chain, New Strategy is on same child chain, but different protocol
    function test_yield_parentPeer_rebalance_oldChild_newChild() public {
        _setStrategy(optChainSelector, keccak256(abi.encodePacked("aave-v3")), SET_CROSS_CHAIN);
        _selectFork(baseFork);
        _changePrank(depositor);

        /// @dev arrange
        /// @notice the current/old strategy chain is the child (opt) and the protocol is Aave
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);
        /// @dev sanity check
        address aUsdc = _getATokenAddress(optNetworkConfig.protocols.aavePoolAddressesProvider, address(optUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(optAaveV3Adapter)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev act
        /// @notice here we are setting the new strategy chain to the same child (opt) whereas the protocol is Compound
        _setStrategy(optChainSelector, keccak256(abi.encodePacked("compound-v3")), SET_CROSS_CHAIN);

        /// @dev assert
        assertEq(IERC20(aUsdc).balanceOf(address(optAaveV3Adapter)), 0);
        uint256 compoundBalance = IComet(optNetworkConfig.protocols.comet).balanceOf(address(optCompoundV3Adapter));
        assertApproxEqAbs(
            compoundBalance,
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Old Strategy is on Parent, New Strategy is on child chain
    function test_yield_parentPeer_rebalance_oldParent_newChild() public {
        _setStrategy(baseChainSelector, keccak256(abi.encodePacked("aave-v3")), SET_CROSS_CHAIN);
        _selectFork(baseFork);
        _changePrank(depositor);

        /// @dev arrange
        /// @notice strategy chain selector here is the parent (base)
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev sanity check
        address aUsdc = _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseAaveV3Adapter)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );

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
    }

    /// @notice Scenario: Old Strategy is on child chain, New Strategy is on Parent
    function test_yield_parentPeer_rebalance_oldChild_newParent() public {
        _setStrategy(optChainSelector, keccak256(abi.encodePacked("aave-v3")), SET_CROSS_CHAIN);
        _selectFork(baseFork);
        _changePrank(depositor);

        /// @dev arrange
        /// @notice the current/old strategy chain is the child (opt) and the protocol is Aave
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);
        /// @dev sanity check
        address aUsdc = _getATokenAddress(optNetworkConfig.protocols.aavePoolAddressesProvider, address(optUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(optAaveV3Adapter)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev act
        /// @notice here we are setting the strategy chain selector to the parent (base)
        _setStrategy(baseChainSelector, keccak256(abi.encodePacked("aave-v3")), NO_CROSS_CHAIN);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);

        /// @dev assert
        address baseAaveUsdc =
            _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(baseAaveUsdc).balanceOf(address(baseAaveV3Adapter)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Old Strategy is on a Child chain, New Strategy is on a different Child chain ("Chain C")
    function test_yield_parentPeer_rebalance_oldChild_newChainC() public {
        _setStrategy(optChainSelector, keccak256(abi.encodePacked("aave-v3")), SET_CROSS_CHAIN);
        _selectFork(baseFork);
        _changePrank(depositor);

        /// @dev arrange
        /// @notice the current/old strategy chain is the child (opt) and the protocol is Aave
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);
        /// @dev sanity check
        address aUsdc = _getATokenAddress(optNetworkConfig.protocols.aavePoolAddressesProvider, address(optUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(optAaveV3Adapter)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev act
        /// @notice here we are setting the strategy chain selector to a different child (eth)
        _setStrategy(ethChainSelector, keccak256(abi.encodePacked("aave-v3")), NO_CROSS_CHAIN);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(ethFork, attesters, attesterPks);

        /// @dev assert
        address ethAaveUsdc = _getATokenAddress(ethNetworkConfig.protocols.aavePoolAddressesProvider, address(ethUsdc));
        assertApproxEqAbs(
            IERC20(ethAaveUsdc).balanceOf(address(ethAaveV3Adapter)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
    }

    function test_yield_parentPeer_setStrategy_revetsWhen_notRebalancer() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("ParentPeer__OnlyRebalancer()"));
        baseParentPeer.setStrategy(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));
    }
}
