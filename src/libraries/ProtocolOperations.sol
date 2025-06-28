// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
import {IComet} from "../interfaces/IComet.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IYieldPeer} from "../interfaces/IYieldPeer.sol";

/// @notice This library facilitates operations on Strategy Protocols (ie depositing and withdrawing from Aave and Compound)
library ProtocolOperations {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ProtocolOperations__InvalidStrategyPool(address strategyPool);

    /*//////////////////////////////////////////////////////////////
                                 CONFIG
    //////////////////////////////////////////////////////////////*/
    /// @notice This will need to be updated as new protocols are added
    struct ProtocolConfig {
        address usdc;
        address aavePoolAddressesProvider;
        address comet;
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Creates a ProtocolConfig struct
    /// @param usdc The address of the USDC token
    /// @param aavePoolAddressesProvider The address of the Aave v3 pool addresses provider
    /// @param comet The address of the Compound v3 pool
    /// @return config The ProtocolConfig struct
    function _createConfig(address usdc, address aavePoolAddressesProvider, address comet)
        internal
        pure
        returns (ProtocolConfig memory)
    {
        return ProtocolConfig({usdc: usdc, aavePoolAddressesProvider: aavePoolAddressesProvider, comet: comet});
    }

    /// @notice Deposits USDC to the strategy pool
    /// @param strategyPool The address of the strategy pool
    /// @param config The ProtocolConfig struct
    /// @param amount The amount of USDC to deposit
    /// @dev Reverts if the strategy pool is invalid
    function _depositToStrategy(address strategyPool, ProtocolConfig memory config, uint256 amount) internal {
        if (strategyPool == address(config.aavePoolAddressesProvider)) {
            _depositToAave(config.usdc, config.aavePoolAddressesProvider, amount);
        } else if (strategyPool == address(config.comet)) {
            _depositToCompound(config.usdc, config.comet, amount);
        } else {
            revert ProtocolOperations__InvalidStrategyPool(strategyPool);
        }
    }

    /// @notice Withdraws USDC from the strategy pool
    /// @param strategyPool The address of the strategy pool
    /// @param config The ProtocolConfig struct
    /// @param amount The amount of USDC to withdraw
    /// @dev Reverts if the strategy pool is invalid
    function _withdrawFromStrategy(address strategyPool, ProtocolConfig memory config, uint256 amount) internal {
        if (strategyPool == address(config.aavePoolAddressesProvider)) {
            _withdrawFromAave(config.usdc, config.aavePoolAddressesProvider, amount);
        } else if (strategyPool == address(config.comet)) {
            _withdrawFromCompound(config.usdc, config.comet, amount);
        } else {
            revert ProtocolOperations__InvalidStrategyPool(strategyPool);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the total value from the strategy pool
    /// @param strategyPool The address of the strategy pool
    /// @param config The ProtocolConfig struct
    /// @return The total value of the strategy pool
    /// @dev Reverts if the strategy pool is invalid
    function _getTotalValueFromStrategy(address strategyPool, ProtocolConfig memory config)
        internal
        view
        returns (uint256)
    {
        if (strategyPool == address(config.aavePoolAddressesProvider)) {
            return _getTotalValueFromAave(config.usdc, config.aavePoolAddressesProvider);
        } else if (strategyPool == address(config.comet)) {
            return _getTotalValueFromCompound(config.comet);
        } else {
            revert ProtocolOperations__InvalidStrategyPool(strategyPool);
        }
    }

    /// @notice Gets the strategy pool from a protocol
    /// @param protocol The protocol
    /// @param config The ProtocolConfig struct
    /// @return strategyPool The address of the strategy pool
    /// @dev Reverts if the protocol is invalid
    function _getStrategyPoolFromProtocol(IYieldPeer.Protocol protocol, ProtocolConfig memory config)
        internal
        pure
        returns (address strategyPool)
    {
        if (protocol == IYieldPeer.Protocol.Aave) strategyPool = config.aavePoolAddressesProvider;
        else if (protocol == IYieldPeer.Protocol.Compound) strategyPool = config.comet;
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits USDC to the Aave pool
    /// @param usdc The USDC token address
    /// @param aavePoolAddressesProvider The address of the Aave v3 pool addresses provider
    /// @param amount The amount of USDC to deposit
    /// @dev Approves the USDC to the Aave pool and deposits the USDC to the Aave pool
    function _depositToAave(address usdc, address aavePoolAddressesProvider, uint256 amount) private {
        address aavePool = IPoolAddressesProvider(aavePoolAddressesProvider).getPool();
        IERC20(usdc).approve(aavePool, amount);
        IPool(aavePool).supply(usdc, amount, address(this), 0);
    }

    /// @notice Deposits USDC to the Compound pool
    /// @param usdc The USDC token address
    /// @param comet The address of the Compound v3 pool
    /// @param amount The amount of USDC to deposit
    /// @dev Approves the USDC to the Compound pool and deposits the USDC to the Compound pool
    function _depositToCompound(address usdc, address comet, uint256 amount) private {
        IERC20(usdc).approve(comet, amount);
        IComet(comet).supply(usdc, amount);
    }

    /// @notice Withdraws USDC from the Aave pool
    /// @param usdc The USDC token address
    /// @param aavePoolAddressesProvider The address of the Aave v3 pool addresses provider
    /// @param amount The amount of USDC to withdraw
    /// @dev Withdraws the USDC from the Aave pool
    function _withdrawFromAave(address usdc, address aavePoolAddressesProvider, uint256 amount) private {
        address aavePool = IPoolAddressesProvider(aavePoolAddressesProvider).getPool();
        IPool(aavePool).withdraw(usdc, amount, address(this));
    }

    /// @notice Withdraws USDC from the Compound pool
    /// @param usdc The USDC token address
    /// @param comet The address of the Compound v3 pool
    /// @param amount The amount of USDC to withdraw
    /// @dev Withdraws the USDC from the Compound pool
    function _withdrawFromCompound(address usdc, address comet, uint256 amount) private {
        IComet(comet).withdraw(usdc, amount);
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL VIEW
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the total value from the Aave pool
    /// @param usdc The USDC token address
    /// @param aavePoolAddressesProvider The address of the Aave v3 pool addresses provider
    /// @return The total value from the Aave pool
    function _getTotalValueFromAave(address usdc, address aavePoolAddressesProvider) private view returns (uint256) {
        address aavePool = IPoolAddressesProvider(aavePoolAddressesProvider).getPool();
        DataTypes.ReserveData memory reserveData = IPool(aavePool).getReserveData(usdc);
        address aTokenAddress = reserveData.aTokenAddress;
        return IERC20(aTokenAddress).balanceOf(address(this));
    }

    /// @notice Gets the total value from the Compound pool
    /// @param comet The address of the Compound v3 pool
    /// @return The total value from the Compound pool
    function _getTotalValueFromCompound(address comet) private view returns (uint256) {
        return IComet(comet).balanceOf(address(this));
    }
}
