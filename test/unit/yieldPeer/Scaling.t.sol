// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";
import {ParentPeer} from "../../../src/peers/ParentPeer.sol";

/// @dev Tests for YieldPeer internal scaling functions
contract ScalingTest is BaseTest {
    ScalingTestHarness internal harness;

    function setUp() public override {
        super.setUp();
        _selectFork(baseFork);
        harness = new ScalingTestHarness();
    }

    /*//////////////////////////////////////////////////////////////
                        _scaleToUsdcDecimals
    //////////////////////////////////////////////////////////////*/
    function test_yield_yieldPeer_scaleToUsdcDecimals_sameDecimals() public view {
        /// @dev 6 decimals to 6 decimals (USDC to USDC) - no change
        uint256 amount = 1_000_000; // 1 USDC
        uint256 result = harness.scaleToUsdcDecimals(amount, 6);
        assertEq(result, amount);
    }

    function test_yield_yieldPeer_scaleToUsdcDecimals_higherToLower() public view {
        /// @dev 18 decimals to 6 decimals (DAI to USDC scale)
        uint256 amount = 1e18; // 1 DAI
        uint256 result = harness.scaleToUsdcDecimals(amount, 18);
        assertEq(result, 1e6); // 1 in USDC decimals
    }

    // @review
    // function test_yield_yieldPeer_scaleToUsdcDecimals_lowerToHigher() public view {
    //     /// @dev 2 decimals to 6 decimals
    //     uint256 amount = 100; // 1 unit with 2 decimals
    //     uint256 result = harness.scaleToUsdcDecimals(amount, 2);
    //     assertEq(result, 10_000); // 1 unit in USDC decimals
    // }

    function test_yield_yieldPeer_scaleToUsdcDecimals_8to6() public view {
        /// @dev 8 decimals to 6 decimals (WBTC style)
        uint256 amount = 1e8; // 1 unit with 8 decimals
        uint256 result = harness.scaleToUsdcDecimals(amount, 8);
        assertEq(result, 1e6);
    }

    /*//////////////////////////////////////////////////////////////
                        _scaleFromUsdcDecimals
    //////////////////////////////////////////////////////////////*/
    function test_yield_yieldPeer_scaleFromUsdcDecimals_sameDecimals() public view {
        /// @dev 6 decimals to 6 decimals - no change
        uint256 amount = 1_000_000; // 1 USDC
        uint256 result = harness.scaleFromUsdcDecimals(amount, 6);
        assertEq(result, amount);
    }

    function test_yield_yieldPeer_scaleFromUsdcDecimals_lowerToHigher() public view {
        /// @dev 6 decimals to 18 decimals (USDC scale to DAI)
        uint256 amount = 1e6; // 1 USDC
        uint256 result = harness.scaleFromUsdcDecimals(amount, 18);
        assertEq(result, 1e18); // 1 in DAI decimals
    }

    // @review
    // function test_yield_yieldPeer_scaleFromUsdcDecimals_higherToLower() public view {
    //     /// @dev 6 decimals to 2 decimals
    //     uint256 amount = 10_000; // 1 unit in USDC decimals
    //     uint256 result = harness.scaleFromUsdcDecimals(amount, 2);
    //     assertEq(result, 100); // 1 unit with 2 decimals
    // }

    function test_yield_yieldPeer_scaleFromUsdcDecimals_6to8() public view {
        /// @dev 6 decimals to 8 decimals
        uint256 amount = 1e6;
        uint256 result = harness.scaleFromUsdcDecimals(amount, 8);
        assertEq(result, 1e8);
    }
}

/// @dev Test harness to expose internal scaling functions
contract ScalingTestHarness is ParentPeer {
    constructor() ParentPeer(address(1), address(1), 1, address(1), address(1)) {}

    function scaleToUsdcDecimals(uint256 amount, uint8 fromDecimals) external pure returns (uint256) {
        return _scaleToUsdcDecimals(amount, fromDecimals);
    }

    function scaleFromUsdcDecimals(uint256 amount, uint8 toDecimals) external pure returns (uint256) {
        return _scaleFromUsdcDecimals(amount, toDecimals);
    }
}
