// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISwapper} from "../interfaces/ISwapper.sol";

/// @notice Interface for Uniswap V3 SwapRouter02 exactInputSingle
interface ISwapRouter02 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

/// @title UniswapV3Swapper
/// @author @contractlevel
/// @notice Swapper implementation using Uniswap V3 SwapRouter02
/// @dev Used by YieldPeer to swap between different stablecoins during rebalancing
contract UniswapV3Swapper is ISwapper {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error UniswapV3Swapper__OnlyYieldPeer();
    error UniswapV3Swapper__ZeroAmount();
    error UniswapV3Swapper__SameToken();
    error UniswapV3Swapper__InsufficientOutput();

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Default fee tier for stablecoin swaps (0.05% = 500)
    /// @dev Uniswap V3 fee tiers: 100 (0.01%), 500 (0.05%), 3000 (0.3%), 10000 (1%)
    uint24 internal constant DEFAULT_FEE_TIER = 500;

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev The YieldPeer contract that can call this swapper
    address internal immutable i_yieldPeer;
    /// @dev The Uniswap V3 SwapRouter02 contract
    ISwapRouter02 internal immutable i_swapRouter;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a swap is executed
    event SwapExecuted(address indexed tokenIn, address indexed tokenOut, uint256 indexed amountOut);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Only the YieldPeer can call this function
    modifier onlyYieldPeer() {
        if (msg.sender != i_yieldPeer) revert UniswapV3Swapper__OnlyYieldPeer();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param yieldPeer The address of the YieldPeer contract
    /// @param swapRouter The address of the Uniswap V3 SwapRouter02 contract
    constructor(address yieldPeer, address swapRouter) {
        i_yieldPeer = yieldPeer;
        i_swapRouter = ISwapRouter02(swapRouter);
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Swap assets from tokenIn to tokenOut using Uniswap V3
    /// @dev Only callable by the YieldPeer contract
    /// @param tokenIn The address of the token to swap from
    /// @param tokenOut The address of the token to swap to
    /// @param amountIn The amount of tokenIn to swap
    /// @param amountOutMin The minimum amount of tokenOut to receive (slippage protection)
    /// @return amountOut The actual amount of tokenOut received
    function swapAssets(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin)
        external
        onlyYieldPeer
        returns (uint256 amountOut)
    {
        if (amountIn == 0) revert UniswapV3Swapper__ZeroAmount();
        if (tokenIn == tokenOut) revert UniswapV3Swapper__SameToken();

        // Transfer tokens from YieldPeer to this contract
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Approve the swap router to spend tokenIn
        IERC20(tokenIn).safeIncreaseAllowance(address(i_swapRouter), amountIn);

        // Build swap params
        ISwapRouter02.ExactInputSingleParams memory params = ISwapRouter02.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: DEFAULT_FEE_TIER,
            recipient: msg.sender, // Send output tokens directly to YieldPeer
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0 // No price limit
        });

        // Execute the swap
        amountOut = i_swapRouter.exactInputSingle(params);

        if (amountOut < amountOutMin) revert UniswapV3Swapper__InsufficientOutput();

        emit SwapExecuted(tokenIn, tokenOut, amountOut);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Get the YieldPeer address
    /// @return The YieldPeer address
    function getYieldPeer() external view returns (address) {
        return i_yieldPeer;
    }

    /// @notice Get the SwapRouter address
    /// @return The SwapRouter address
    function getSwapRouter() external view returns (address) {
        return address(i_swapRouter);
    }

    /// @notice Get the default fee tier used for swaps
    /// @return The fee tier in hundredths of a basis point (500 = 0.05%)
    function getDefaultFeeTier() external pure returns (uint24) {
        return DEFAULT_FEE_TIER;
    }
}
