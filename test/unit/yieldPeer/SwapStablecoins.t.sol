// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Roles} from "../../BaseTest.t.sol";
import {ParentPeer} from "../../../src/peers/ParentPeer.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Tests for YieldPeer _swapStablecoins internal function
contract SwapStablecoinsTest is BaseTest {
    SwapTestHarness internal harness;
    MockSwapper internal mockSwapper;
    MockStablecoin internal mockUsdt;

    function setUp() public override {
        super.setUp();
        _selectFork(baseFork);

        harness = new SwapTestHarness(
            address(baseNetworkConfig.ccip.ccipRouter),
            address(baseNetworkConfig.tokens.link),
            baseChainSelector,
            address(baseUsdc),
            address(baseShare)
        );

        mockUsdt = new MockStablecoin("Mock USDT", "USDT", 6);
        mockSwapper = new MockSwapper();

        /// @dev set swapper on harness
        _changePrank(harness.owner());
        harness.grantRole(Roles.CONFIG_ADMIN_ROLE, harness.owner());
        harness.setSwapper(address(mockSwapper));
    }

    /*//////////////////////////////////////////////////////////////
                          _swapStablecoins
    //////////////////////////////////////////////////////////////*/
    function test_yield_yieldPeer_swapStablecoins_returnsSameAmountWhen_sameToken() public {
        uint256 amount = 1_000_000;
        deal(address(baseUsdc), address(harness), amount);

        uint256 result = harness.swapStablecoins(address(baseUsdc), address(baseUsdc), amount);
        assertEq(result, amount);
    }

    function test_yield_yieldPeer_swapStablecoins_returnsSameAmountWhen_zeroAmount() public {
        uint256 result = harness.swapStablecoins(address(baseUsdc), address(mockUsdt), 0);
        assertEq(result, 0);
    }

    function test_yield_yieldPeer_swapStablecoins_revertsWhen_noSwapper() public {
        /// @dev create new harness without swapper
        SwapTestHarness harnessNoSwapper = new SwapTestHarness(
            address(baseNetworkConfig.ccip.ccipRouter),
            address(baseNetworkConfig.tokens.link),
            baseChainSelector,
            address(baseUsdc),
            address(baseShare)
        );

        uint256 amount = 1_000_000;
        deal(address(baseUsdc), address(harnessNoSwapper), amount);

        vm.expectRevert(abi.encodeWithSignature("YieldPeer__NoZeroAmount()"));
        harnessNoSwapper.swapStablecoins(address(baseUsdc), address(mockUsdt), amount);
    }

    function test_yield_yieldPeer_swapStablecoins_swapsSuccessfully() public {
        uint256 amountIn = 1_000_000;
        uint256 expectedAmountOut = 999_000; // Mock swapper returns slightly less

        deal(address(baseUsdc), address(harness), amountIn);
        deal(address(mockUsdt), address(mockSwapper), expectedAmountOut);

        mockSwapper.setReturnAmount(expectedAmountOut);

        uint256 result = harness.swapStablecoins(address(baseUsdc), address(mockUsdt), amountIn);
        assertEq(result, expectedAmountOut);
    }

    function test_yield_yieldPeer_swapStablecoins_emitsEvent() public {
        uint256 amountIn = 1_000_000;
        uint256 expectedAmountOut = 999_000;

        deal(address(baseUsdc), address(harness), amountIn);
        deal(address(mockUsdt), address(mockSwapper), expectedAmountOut);

        mockSwapper.setReturnAmount(expectedAmountOut);

        vm.expectEmit(true, true, true, false);
        emit StablecoinsSwapped(address(baseUsdc), address(mockUsdt), expectedAmountOut);

        harness.swapStablecoins(address(baseUsdc), address(mockUsdt), amountIn);
    }

    function test_yield_yieldPeer_swapStablecoins_crossDecimalSwap_18to6() public {
        /// @dev Test swapping 18 decimal token to 6 decimal token
        MockStablecoin mockDai = new MockStablecoin("Mock DAI", "DAI", 18);
        uint256 amountIn = 1e18; // 1 DAI
        uint256 expectedAmountOut = 1e6; // ~1 USDC

        deal(address(mockDai), address(harness), amountIn);
        deal(address(baseUsdc), address(mockSwapper), expectedAmountOut);

        mockSwapper.setReturnAmount(expectedAmountOut);

        uint256 result = harness.swapStablecoins(address(mockDai), address(baseUsdc), amountIn);
        assertEq(result, expectedAmountOut);
    }

    event StablecoinsSwapped(address indexed tokenIn, address indexed tokenOut, uint256 indexed amountOut);
}

/// @dev Test harness to expose internal swap functions
contract SwapTestHarness is ParentPeer {
    constructor(address ccipRouter, address link, uint64 chainSelector, address usdc, address share)
        ParentPeer(ccipRouter, link, chainSelector, usdc, share)
    {}

    function swapStablecoins(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256) {
        return _swapStablecoins(tokenIn, tokenOut, amountIn);
    }
}

/// @dev Mock swapper for testing
contract MockSwapper {
    uint256 private s_returnAmount;

    function setReturnAmount(uint256 amount) external {
        s_returnAmount = amount;
    }

    function swapAssets(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 /* amountOutMin */
    )
        external
        returns (uint256)
    {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, s_returnAmount);
        return s_returnAmount;
    }
}

/// @dev Mock stablecoin for testing
contract MockStablecoin is ERC20 {
    uint8 private immutable _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
