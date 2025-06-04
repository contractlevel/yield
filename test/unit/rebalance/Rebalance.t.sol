// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IERC20, Vm, IYieldPeer, IComet} from "../../BaseTest.t.sol";

contract RebalanceTest is BaseTest {
    function setUp() public override {
        super.setUp();
        /// @dev baseFork is the parent chain
        _selectFork(baseFork);
        deal(address(baseUsdc), depositor, DEPOSIT_AMOUNT);
        _changePrank(depositor);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
    }

    /// @notice Scenario: New Strategy is same as the old
    function test_yield_rebalance_sameStrategy() public {
        /// @dev arrange
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev sanity check
        address aUsdc = _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseParentPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );

        vm.recordLogs();

        /// @dev act
        /// @notice the strategy chain and protocol are the same as the old strategy
        baseParentPeer.rebalance(
            IYieldPeer.Strategy({chainSelector: baseChainSelector, protocol: IYieldPeer.Protocol.Aave})
        );

        /// @dev assert
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 eventSignature = keccak256("CurrentStrategyOptimal(uint64,uint8)");
        uint64 emittedChainSelector;
        uint8 emittedProtocol;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == eventSignature) {
                emittedChainSelector = uint64(uint256(logs[i].topics[1]));
                emittedProtocol = uint8(uint256(logs[i].topics[2]));
            }
        }
        assertEq(emittedChainSelector, baseChainSelector);
        assertEq(emittedProtocol, uint8(IYieldPeer.Protocol.Aave));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseParentPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Old Strategy and New are both on Parent, but different protocols
    function test_yield_rebalance_oldParent_newParent() public {
        /// @dev arrange
        /// @notice the current/old strategy chain is the parent (base) whereas the protocl is Aave
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev sanity check
        address aUsdc = _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseParentPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );

        /// @dev act
        /// @notice here we are setting the new strategy chain to the same parent (base) whereas the protocol is Compound
        baseParentPeer.rebalance(
            IYieldPeer.Strategy({chainSelector: baseChainSelector, protocol: IYieldPeer.Protocol.Compound})
        );

        /// @dev assert
        assertEq(IERC20(aUsdc).balanceOf(address(baseParentPeer)), 0);
        uint256 compoundBalance = IComet(baseNetworkConfig.protocols.comet).balanceOf(address(baseParentPeer));
        assertApproxEqAbs(
            compoundBalance,
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Old Strategy is on child chain, New Strategy is on same child chain, but different protocol
    function test_yield_rebalance_oldChild_newChild() public {
        // @review REMOVE THIS AND REPLACE WITH CLF CALL
        _selectFork(optFork);
        optChildPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(baseFork);
        baseParentPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);

        /// @dev arrange
        /// @notice the current/old strategy chain is the child (opt) and the protocol is Aave
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);
        /// @dev sanity check
        address aUsdc = _getATokenAddress(optNetworkConfig.protocols.aavePoolAddressesProvider, address(optUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(optChildPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev act
        /// @notice here we are setting the new strategy chain to the same child (opt) whereas the protocol is Compound
        baseParentPeer.rebalance(
            IYieldPeer.Strategy({chainSelector: optChainSelector, protocol: IYieldPeer.Protocol.Compound})
        );
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert
        assertEq(IERC20(aUsdc).balanceOf(address(optChildPeer)), 0);
        uint256 compoundBalance = IComet(optNetworkConfig.protocols.comet).balanceOf(address(optChildPeer));
        assertApproxEqAbs(
            compoundBalance,
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Compound balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Old Strategy is on Parent, New Strategy is on child chain
    function test_yield_rebalance_oldParent_newChild() public {
        // @review REMOVE THIS AND REPLACE WITH CLF CALL
        _selectFork(optFork);
        optChildPeer.setStrategy(baseChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(baseFork);

        /// @dev arrange
        /// @notice strategy chain selector here is the parent (base)
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        /// @dev sanity check
        address aUsdc = _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(baseParentPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );

        /// @dev act
        /// @notice here we are setting the strategy chain selector to a child (opt)
        baseParentPeer.rebalance(
            IYieldPeer.Strategy({chainSelector: optChainSelector, protocol: IYieldPeer.Protocol.Aave})
        );
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);

        /// @dev assert
        address optAaveUsdc = _getATokenAddress(optNetworkConfig.protocols.aavePoolAddressesProvider, address(optUsdc));
        assertApproxEqAbs(
            IERC20(optAaveUsdc).balanceOf(address(optChildPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Old Strategy is on child chain, New Strategy is on Parent
    function test_yield_rebalance_oldChild_newParent() public {
        // @review REMOVE THIS AND REPLACE WITH CLF CALL
        _selectFork(optFork);
        optChildPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(baseFork);
        baseParentPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);

        /// @dev arrange
        /// @notice the current/old strategy chain is the child (opt) and the protocol is Aave
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);
        /// @dev sanity check
        address aUsdc = _getATokenAddress(optNetworkConfig.protocols.aavePoolAddressesProvider, address(optUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(optChildPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev act
        /// @notice here we are setting the strategy chain selector to the parent (base)
        baseParentPeer.rebalance(
            IYieldPeer.Strategy({chainSelector: baseChainSelector, protocol: IYieldPeer.Protocol.Aave})
        );
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(baseFork, attesters, attesterPks);

        /// @dev assert
        address baseAaveUsdc =
            _getATokenAddress(baseNetworkConfig.protocols.aavePoolAddressesProvider, address(baseUsdc));
        assertApproxEqAbs(
            IERC20(baseAaveUsdc).balanceOf(address(baseParentPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
    }

    /// @notice Scenario: Old Strategy is on a Child chain, New Strategy is on a different Child chain ("Chain C")
    function test_yield_rebalance_oldChild_newChainC() public {
        // @review REMOVE THIS AND REPLACE WITH CLF CALL
        _selectFork(ethFork);
        ethChildPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(optFork);
        optChildPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);
        _selectFork(baseFork);
        baseParentPeer.setStrategy(optChainSelector, IYieldPeer.Protocol.Aave);

        /// @dev arrange
        /// @notice the current/old strategy chain is the child (opt) and the protocol is Aave
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(optFork, attesters, attesterPks);
        /// @dev sanity check
        address aUsdc = _getATokenAddress(optNetworkConfig.protocols.aavePoolAddressesProvider, address(optUsdc));
        assertApproxEqAbs(
            IERC20(aUsdc).balanceOf(address(optChildPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
        ccipLocalSimulatorFork.switchChainAndRouteMessage(baseFork);

        /// @dev act
        /// @notice here we are setting the strategy chain selector to a different child (eth)
        baseParentPeer.rebalance(
            IYieldPeer.Strategy({chainSelector: ethChainSelector, protocol: IYieldPeer.Protocol.Aave})
        );
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);
        ccipLocalSimulatorFork.switchChainAndRouteMessageWithUSDC(ethFork, attesters, attesterPks);

        /// @dev assert
        address ethAaveUsdc = _getATokenAddress(ethNetworkConfig.protocols.aavePoolAddressesProvider, address(ethUsdc));
        assertApproxEqAbs(
            IERC20(ethAaveUsdc).balanceOf(address(ethChildPeer)),
            DEPOSIT_AMOUNT,
            BALANCE_TOLERANCE,
            "Aave balance should be approximately equal to deposit amount"
        );
    }
}
