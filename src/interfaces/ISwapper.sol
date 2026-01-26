// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title ISwapper
/// @author @contractlevel
/// @notice Interface for swapping assets (stablecoins)
/// @dev Used by YieldPeer to swap between different stablecoins during rebalancing
interface ISwapper {
    /// @notice Swap assets from tokenIn to tokenOut
    /// @param tokenIn The address of the token to swap from
    /// @param tokenOut The address of the token to swap to
    /// @param amountIn The amount of tokenIn to swap
    /// @param amountOutMin The minimum amount of tokenOut to receive (slippage protection)
    /// @return amountOut The actual amount of tokenOut received
    function swapAssets(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin)
        external
        returns (uint256 amountOut);
}
