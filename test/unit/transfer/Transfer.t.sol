// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";
import {YieldPeer} from "../../../src/peers/YieldPeer.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TransferTest is BaseTest {
    ExamplePeer examplePeer;
    RevertToken revertToken;
    uint256 amountToTransfer = 100;

    function setUp() public override {
        super.setUp();
        revertToken = new RevertToken();
        examplePeer = new ExamplePeer(
            baseNetworkConfig.ccip.ccipRouter,
            baseNetworkConfig.tokens.link,
            baseNetworkConfig.ccip.thisChainSelector,
            address(revertToken),
            baseNetworkConfig.tokens.share
        );

        deal(address(revertToken), address(examplePeer), amountToTransfer);
    }

    function test_yield_transfer_revertsWhen_transferFails() public {
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__USDCTransferFailed()"));
        examplePeer.transferTo(address(1), amountToTransfer);
    }

    function test_yield_transferFrom_revertsWhen_transferFromFails() public {
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__USDCTransferFailed()"));
        examplePeer.transferFrom(address(1), address(1), amountToTransfer);
    }
}

/// @notice Token that reverts on transfer and transferFrom
contract RevertToken is ERC20 {
    constructor() ERC20("RevertToken", "RT") {}

    function transfer(address, uint256) public pure override returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        return false;
    }

    /// @notice empty test to skip file in coverage
    function test_emptyTest() public {}
}

/// @notice Example peer to test transfer reverts
contract ExamplePeer is YieldPeer {
    constructor(address ccipRouter, address link, uint64 thisChainSelector, address usdc, address share)
        YieldPeer(ccipRouter, link, thisChainSelector, usdc, share)
    {}

    function transferTo(address to, uint256 amount) external {
        _transferUsdcTo(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external {
        _transferUsdcFrom(from, to, amount);
    }

    function deposit(uint256 amountToDeposit) external override {}

    function onTokenTransfer(address withdrawer, uint256 shareBurnAmount, bytes calldata /* data */ )
        external
        override
    {}

    function _handleCCIPMessage(
        CcipTxType txType,
        Client.EVMTokenAmount[] memory tokenAmounts,
        bytes memory data,
        uint64 sourceChainSelector
    ) internal override {}

    /// @notice empty test to skip file in coverage
    function test_emptyTest() public {}
}
