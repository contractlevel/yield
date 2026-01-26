// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {UniswapV3Swapper, ISwapRouter02} from "../../../src/swappers/UniswapV3Swapper.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Mock ERC20 token for testing
contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @dev Mock SwapRouter02 for testing
contract MockSwapRouter02 {
    uint256 public amountOutMultiplier = 100; // 100% of input by default

    function setAmountOutMultiplier(uint256 multiplier) external {
        amountOutMultiplier = multiplier;
    }

    function exactInputSingle(ISwapRouter02.ExactInputSingleParams calldata params)
        external
        returns (uint256 amountOut)
    {
        // Transfer tokenIn from sender
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);

        // Calculate amountOut (simulate 1:1 swap for stablecoins with multiplier)
        amountOut = (params.amountIn * amountOutMultiplier) / 100;

        // Mint tokenOut to recipient (using mock token)
        MockToken(params.tokenOut).mint(params.recipient, amountOut);

        return amountOut;
    }
}

contract UniswapV3SwapperTest is Test {
    UniswapV3Swapper public swapper;
    MockSwapRouter02 public mockRouter;
    MockToken public tokenIn;
    MockToken public tokenOut;

    address public yieldPeer;
    address public notYieldPeer;

    uint256 public constant SWAP_AMOUNT = 1000e6;

    event SwapExecuted(address indexed tokenIn, address indexed tokenOut, uint256 indexed amountOut);

    function setUp() public {
        yieldPeer = makeAddr("yieldPeer");
        notYieldPeer = makeAddr("notYieldPeer");

        mockRouter = new MockSwapRouter02();
        tokenIn = new MockToken("Token In", "TIN");
        tokenOut = new MockToken("Token Out", "TOUT");

        swapper = new UniswapV3Swapper(yieldPeer, address(mockRouter));

        // Mint tokens to yieldPeer for testing
        tokenIn.mint(yieldPeer, SWAP_AMOUNT * 10);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    function test_yield_uniswapV3Swapper_constructor_setsYieldPeer() public view {
        assertEq(swapper.getYieldPeer(), yieldPeer);
    }

    function test_yield_uniswapV3Swapper_constructor_setsSwapRouter() public view {
        assertEq(swapper.getSwapRouter(), address(mockRouter));
    }

    /*//////////////////////////////////////////////////////////////
                            SWAP ASSETS
    //////////////////////////////////////////////////////////////*/
    function test_yield_uniswapV3Swapper_swapAssets_revertsWhen_notYieldPeer() public {
        vm.prank(notYieldPeer);
        vm.expectRevert(abi.encodeWithSignature("UniswapV3Swapper__OnlyYieldPeer()"));
        swapper.swapAssets(address(tokenIn), address(tokenOut), SWAP_AMOUNT, 0);
    }

    function test_yield_uniswapV3Swapper_swapAssets_revertsWhen_zeroAmount() public {
        vm.prank(yieldPeer);
        vm.expectRevert(abi.encodeWithSignature("UniswapV3Swapper__ZeroAmount()"));
        swapper.swapAssets(address(tokenIn), address(tokenOut), 0, 0);
    }

    function test_yield_uniswapV3Swapper_swapAssets_revertsWhen_sameToken() public {
        vm.prank(yieldPeer);
        vm.expectRevert(abi.encodeWithSignature("UniswapV3Swapper__SameToken()"));
        swapper.swapAssets(address(tokenIn), address(tokenIn), SWAP_AMOUNT, 0);
    }

    function test_yield_uniswapV3Swapper_swapAssets_success() public {
        vm.startPrank(yieldPeer);
        tokenIn.approve(address(swapper), SWAP_AMOUNT);

        uint256 balanceBefore = tokenOut.balanceOf(yieldPeer);
        uint256 amountOut = swapper.swapAssets(address(tokenIn), address(tokenOut), SWAP_AMOUNT, 0);
        uint256 balanceAfter = tokenOut.balanceOf(yieldPeer);

        assertEq(amountOut, SWAP_AMOUNT);
        assertEq(balanceAfter - balanceBefore, SWAP_AMOUNT);
        vm.stopPrank();
    }

    function test_yield_uniswapV3Swapper_swapAssets_emitsEvent() public {
        vm.startPrank(yieldPeer);
        tokenIn.approve(address(swapper), SWAP_AMOUNT);

        vm.expectEmit(true, true, true, false);
        emit SwapExecuted(address(tokenIn), address(tokenOut), SWAP_AMOUNT);
        swapper.swapAssets(address(tokenIn), address(tokenOut), SWAP_AMOUNT, 0);
        vm.stopPrank();
    }

    function test_yield_uniswapV3Swapper_swapAssets_transfersTokensCorrectly() public {
        vm.startPrank(yieldPeer);
        uint256 yieldPeerBalanceBefore = tokenIn.balanceOf(yieldPeer);
        tokenIn.approve(address(swapper), SWAP_AMOUNT);

        swapper.swapAssets(address(tokenIn), address(tokenOut), SWAP_AMOUNT, 0);

        uint256 yieldPeerBalanceAfter = tokenIn.balanceOf(yieldPeer);
        assertEq(yieldPeerBalanceBefore - yieldPeerBalanceAfter, SWAP_AMOUNT);
        vm.stopPrank();
    }

    function test_yield_uniswapV3Swapper_swapAssets_respectsSlippage() public {
        // Set router to return less than input (95%)
        mockRouter.setAmountOutMultiplier(95);

        vm.startPrank(yieldPeer);
        tokenIn.approve(address(swapper), SWAP_AMOUNT);

        // This should work since amountOutMin is 0
        uint256 amountOut = swapper.swapAssets(address(tokenIn), address(tokenOut), SWAP_AMOUNT, 0);
        assertEq(amountOut, (SWAP_AMOUNT * 95) / 100);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                              GETTERS
    //////////////////////////////////////////////////////////////*/
    function test_yield_uniswapV3Swapper_getYieldPeer() public view {
        assertEq(swapper.getYieldPeer(), yieldPeer);
    }

    function test_yield_uniswapV3Swapper_getSwapRouter() public view {
        assertEq(swapper.getSwapRouter(), address(mockRouter));
    }

    function test_yield_uniswapV3Swapper_getDefaultFeeTier() public view {
        assertEq(swapper.getDefaultFeeTier(), 500);
    }
}
