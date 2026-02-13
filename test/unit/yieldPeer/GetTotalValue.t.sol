// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Roles} from "../../BaseTest.t.sol";
import {ParentPeer} from "../../../src/peers/ParentPeer.sol";
import {IStrategyAdapter} from "../../../src/interfaces/IStrategyAdapter.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Tests for YieldPeer _getTotalValue internal function with non-USDC stablecoins
contract GetTotalValueTest is BaseTest {
    GetTotalValueHarness internal harness;
    MockAdapter internal mockAdapter;
    MockStablecoin internal mockDai;

    bytes32 internal constant MOCK_PROTOCOL_ID = keccak256("mock-protocol");
    bytes32 internal constant DAI_ID = keccak256("DAI");

    function setUp() public override {
        super.setUp();
        _selectFork(baseFork);

        /// @dev create mock 18 decimal stablecoin
        mockDai = new MockStablecoin("Mock DAI", "DAI", 18);

        /// @dev create mock adapter
        mockAdapter = new MockAdapter();

        /// @dev create harness with proper constructor args
        harness = new GetTotalValueHarness(
            address(baseNetworkConfig.ccip.ccipRouter),
            address(baseNetworkConfig.tokens.link),
            baseChainSelector,
            address(baseUsdc),
            address(baseShare)
        );

        /// @dev set up harness with strategy registry and mock adapter
        _changePrank(harness.owner());
        harness.grantRole(Roles.CONFIG_ADMIN_ROLE, harness.owner());
        harness.setStrategyRegistry(address(baseStrategyRegistry));

        /// @dev set mock adapter in strategy registry
        _changePrank(baseStrategyRegistry.owner());
        baseStrategyRegistry.setStrategyAdapter(MOCK_PROTOCOL_ID, address(mockAdapter));
        baseStrategyRegistry.setStablecoin(DAI_ID, address(mockDai));

        /// @dev set active strategy to mock protocol with DAI stablecoin
        _changePrank(harness.owner());
        harness.setActiveStrategyForTest(address(mockAdapter), address(mockDai));
    }

    /*//////////////////////////////////////////////////////////////
                          _getTotalValue (non-USDC)
    //////////////////////////////////////////////////////////////*/
    function test_yield_yieldPeer_getTotalValue_withNonUsdcStablecoin() public {
        /// @dev Set mock adapter to return 1000 DAI (18 decimals)
        uint256 daiAmount = 1000e18;
        mockAdapter.setTotalValue(daiAmount);

        /// @dev getTotalValue should scale 18 decimals to 6 decimals
        uint256 totalValue = harness.getTotalValue();

        /// @dev 1000 DAI (18 dec) should become 1000 USDC (6 dec)
        assertEq(totalValue, 1000e6);
    }

    function test_yield_yieldPeer_getTotalValue_withUsdcStablecoin() public {
        /// @dev change active stablecoin to USDC
        _changePrank(harness.owner());
        harness.setActiveStrategyForTest(address(mockAdapter), address(baseUsdc));

        /// @dev Set mock adapter to return 1000 USDC
        uint256 usdcAmount = 1000e6;
        mockAdapter.setTotalValue(usdcAmount);

        /// @dev getTotalValue should not scale when using USDC
        uint256 totalValue = harness.getTotalValue();
        assertEq(totalValue, usdcAmount);
    }

    function test_yield_yieldPeer_getTotalValue_revertsWhen_notStrategyChain() public {
        /// @dev set active strategy adapter to address(0)
        _changePrank(harness.owner());
        harness.setActiveStrategyForTest(address(0), address(0));

        vm.expectRevert(abi.encodeWithSignature("YieldPeer__NotStrategyChain()"));
        harness.getTotalValue();
    }
}

/// @dev Test harness to expose internal functions
contract GetTotalValueHarness is ParentPeer {
    constructor(address ccipRouter, address link, uint64 chainSelector, address usdc, address share)
        ParentPeer(ccipRouter, link, chainSelector, usdc, share)
    {}

    function setActiveStrategyForTest(address adapter, address stablecoin) external {
        s_activeStrategyAdapter = adapter;
        s_activeStablecoin = stablecoin;
    }
}

/// @dev Mock adapter for testing
contract MockAdapter is IStrategyAdapter {
    uint256 private s_totalValue;

    function setTotalValue(uint256 value) external {
        s_totalValue = value;
    }

    function deposit(address, uint256) external override {}

    function withdraw(address, uint256) external override {}

    function getTotalValue(address) external view override returns (uint256) {
        return s_totalValue;
    }

    function getStrategyPool() external view override returns (address) {
        return address(0);
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
