// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";
import {ProtocolOperations} from "../../../src/libraries/ProtocolOperations.sol";
import {IYieldPeer} from "../../../src/interfaces/IYieldPeer.sol";

contract ProtocolOperationsTest is BaseTest {
    ProtocolOperationsClient protocolOperationsClient;
    uint256 amount = 1e18;

    function setUp() public override {
        super.setUp();
        protocolOperationsClient = new ProtocolOperationsClient();
    }

    function test_protocolOperations_depositToStrategy_revertsWhen_invalidStrategyPool() public {
        /// @dev arrange
        address invalidProtocol = makeAddr("invalidProtocol");

        ProtocolOperations.ProtocolConfig memory config = protocolOperationsClient.createConfig(
            address(baseUsdc),
            address(baseNetworkConfig.protocols.aavePoolAddressesProvider),
            address(baseNetworkConfig.protocols.comet)
        );

        /// @dev act/assert
        vm.expectRevert(abi.encodeWithSignature("ProtocolOperations__InvalidStrategyPool(address)", invalidProtocol));
        protocolOperationsClient.depositToStrategy(invalidProtocol, config, amount);
    }

    function test_protocolOperations_withdrawFromStrategy_revertsWhen_invalidStrategyPool() public {
        /// @dev arrange
        address invalidProtocol = makeAddr("invalidProtocol");

        ProtocolOperations.ProtocolConfig memory config = protocolOperationsClient.createConfig(
            address(baseUsdc),
            address(baseNetworkConfig.protocols.aavePoolAddressesProvider),
            address(baseNetworkConfig.protocols.comet)
        );

        /// @dev act/assert
        vm.expectRevert(abi.encodeWithSignature("ProtocolOperations__InvalidStrategyPool(address)", invalidProtocol));
        protocolOperationsClient.withdrawFromStrategy(invalidProtocol, config, amount);
    }

    function test_getTotalValueFromStrategy_revertsWhen_invalidStrategyPool() public {
        /// @dev arrange
        address invalidProtocol = makeAddr("invalidProtocol");

        ProtocolOperations.ProtocolConfig memory config = protocolOperationsClient.createConfig(
            address(baseUsdc),
            address(baseNetworkConfig.protocols.aavePoolAddressesProvider),
            address(baseNetworkConfig.protocols.comet)
        );

        /// @dev act/assert
        vm.expectRevert(abi.encodeWithSignature("ProtocolOperations__InvalidStrategyPool(address)", invalidProtocol));
        protocolOperationsClient.getTotalValueFromStrategy(invalidProtocol, config);
    }

    function test_getStrategyPoolFromProtocol_returnsAavePoolAddressesProviderWhen_protocolIsAave() public view {
        /// @dev arrange
        ProtocolOperations.ProtocolConfig memory config = protocolOperationsClient.createConfig(
            address(baseUsdc),
            address(baseNetworkConfig.protocols.aavePoolAddressesProvider),
            address(baseNetworkConfig.protocols.comet)
        );
        /// @dev act
        address strategyPool = protocolOperationsClient.getStrategyPoolFromProtocol(IYieldPeer.Protocol.Aave, config);
        /// @dev assert
        assertEq(strategyPool, baseNetworkConfig.protocols.aavePoolAddressesProvider);
    }

    function test_getStrategyPoolFromProtocol_returnsCometWhen_protocolIsCompound() public view {
        /// @dev arrange
        ProtocolOperations.ProtocolConfig memory config = protocolOperationsClient.createConfig(
            address(baseUsdc),
            address(baseNetworkConfig.protocols.aavePoolAddressesProvider),
            address(baseNetworkConfig.protocols.comet)
        );
        /// @dev act
        address strategyPool =
            protocolOperationsClient.getStrategyPoolFromProtocol(IYieldPeer.Protocol.Compound, config);
        /// @dev assert
        assertEq(strategyPool, baseNetworkConfig.protocols.comet);
    }
}

contract ProtocolOperationsClient {
    function createConfig(address usdc, address aavePoolAddressesProvider, address comet)
        external
        pure
        returns (ProtocolOperations.ProtocolConfig memory)
    {
        return ProtocolOperations.createConfig(usdc, aavePoolAddressesProvider, comet);
    }

    function depositToStrategy(address strategyPool, ProtocolOperations.ProtocolConfig memory config, uint256 amount)
        external
    {
        ProtocolOperations.depositToStrategy(strategyPool, config, amount);
    }

    function withdrawFromStrategy(address strategyPool, ProtocolOperations.ProtocolConfig memory config, uint256 amount)
        external
    {
        ProtocolOperations.withdrawFromStrategy(strategyPool, config, amount);
    }

    function getTotalValueFromStrategy(address strategyPool, ProtocolOperations.ProtocolConfig memory config)
        external
        view
        returns (uint256)
    {
        return ProtocolOperations.getTotalValueFromStrategy(strategyPool, config);
    }

    function getStrategyPoolFromProtocol(IYieldPeer.Protocol protocol, ProtocolOperations.ProtocolConfig memory config)
        external
        pure
        returns (address)
    {
        return ProtocolOperations.getStrategyPoolFromProtocol(protocol, config);
    }
}
