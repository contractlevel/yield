// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";
import {Client, IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IYieldPeer} from "../../../src/interfaces/IYieldPeer.sol";
import {CCIPOperations, IERC20} from "../../../src/libraries/CCIPOperations.sol";
import {DataStructures} from "../../../src/libraries/DataStructures.sol";

contract CCIPOperationsTest is BaseTest {
    CCIPOperationsClient ccipOperationsClient;

    function setUp() public override {
        super.setUp();
        ccipOperationsClient = new CCIPOperationsClient();
        _setStrategy(optChainSelector, keccak256(abi.encodePacked("aave-v3")), SET_CROSS_CHAIN);
        _dealAndApproveUsdc(baseFork, depositor, address(baseParentPeer), DEPOSIT_AMOUNT);
    }

    function test_yield_ccipOperations_handleCCIPFees_revertsWhen_notEnoughLink() public {
        /// @dev arrange
        _selectFork(baseFork);
        address link = baseNetworkConfig.tokens.link;
        address ccipRouter = baseNetworkConfig.ccip.ccipRouter;
        uint256 linkBalance = LinkTokenInterface(link).balanceOf(address(baseParentPeer));
        address burner = makeAddr("burner");
        _changePrank(address(baseParentPeer));
        LinkTokenInterface(link).transfer(burner, linkBalance);

        _changePrank(depositor);
        Client.EVMTokenAmount[] memory tokenAmounts =
            CCIPOperations._prepareTokenAmounts(baseUsdc, DEPOSIT_AMOUNT, ccipRouter);
        IYieldPeer.DepositData memory depositData =
            DataStructures.buildDepositData(depositor, DEPOSIT_AMOUNT, baseChainSelector);
        Client.EVM2AnyMessage memory evm2AnyMessage = CCIPOperations._buildCCIPMessage(
            address(optChildPeer),
            IYieldPeer.CcipTxType.DepositToStrategy,
            abi.encode(depositData),
            tokenAmounts,
            baseParentPeer.getCCIPGasLimit(),
            link
        );
        // Get the actual fee amount from the router
        uint256 fees = IRouterClient(ccipRouter).getFee(optChainSelector, evm2AnyMessage);
        /// @dev act/assert
        vm.expectRevert(abi.encodeWithSignature("CCIPOperations__NotEnoughLink(uint256,uint256)", 0, fees));
        baseParentPeer.deposit(USDC_ID, DEPOSIT_AMOUNT);
    }

    function test_yield_ccipOperations_validateTokenAmounts_revertsWhen_invalidToken() public {
        /// @dev arrange
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: baseNetworkConfig.tokens.link, amount: DEPOSIT_AMOUNT});

        /// @dev act/assert
        vm.expectRevert(abi.encodeWithSignature("CCIPOperations__InvalidToken(address)", baseNetworkConfig.tokens.link));
        ccipOperationsClient.validateTokenAmounts(tokenAmounts, address(baseUsdc), DEPOSIT_AMOUNT);
    }

    function test_yield_ccipOperations_validateTokenAmounts_revertsWhen_invalidAmount() public {
        /// @dev arrange
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: address(baseUsdc), amount: DEPOSIT_AMOUNT});

        /// @dev act/assert
        vm.expectRevert(abi.encodeWithSignature("CCIPOperations__InvalidTokenAmount(uint256)", DEPOSIT_AMOUNT));
        ccipOperationsClient.validateTokenAmounts(tokenAmounts, address(baseUsdc), DEPOSIT_AMOUNT - 1);
    }

    function test_yield_ccipOperations_prepareTokenAmounts_returnsEmptyArrayWhen_bridgeAmountIsZero() public {
        /// @dev arrange
        _selectFork(baseFork);
        address ccipRouter = baseNetworkConfig.ccip.ccipRouter;

        /// @dev act
        Client.EVMTokenAmount[] memory tokenAmounts =
            ccipOperationsClient.prepareTokenAmounts(address(baseUsdc), 0, ccipRouter);

        /// @dev assert
        assertEq(tokenAmounts.length, 0);
        assertEq(baseUsdc.allowance(address(ccipOperationsClient), ccipRouter), 0);
    }

    function test_yield_ccipOperations_prepareTokenAmounts_returnsCorrectTokenAmountsWhen_bridgeAmountIsGreaterThanZero()
        public
    {
        /// @dev arrange
        _selectFork(baseFork);
        address ccipRouter = baseNetworkConfig.ccip.ccipRouter;

        /// @dev act
        Client.EVMTokenAmount[] memory tokenAmounts =
            ccipOperationsClient.prepareTokenAmounts(address(baseUsdc), DEPOSIT_AMOUNT, ccipRouter);

        /// @dev assert
        assertEq(tokenAmounts.length, 1);
        assertEq(tokenAmounts[0].token, address(baseUsdc));
        assertEq(tokenAmounts[0].amount, DEPOSIT_AMOUNT);
        assertEq(baseUsdc.allowance(address(ccipOperationsClient), ccipRouter), DEPOSIT_AMOUNT);
    }
}

contract CCIPOperationsClient {
    function validateTokenAmounts(Client.EVMTokenAmount[] memory tokenAmounts, address usdc, uint256 amount)
        external
        pure
    {
        CCIPOperations._validateTokenAmounts(tokenAmounts, usdc, amount);
    }

    function prepareTokenAmounts(address usdc, uint256 bridgeAmount, address ccipRouter)
        external
        returns (Client.EVMTokenAmount[] memory tokenAmounts)
    {
        return CCIPOperations._prepareTokenAmounts(IERC20(usdc), bridgeAmount, ccipRouter);
    }

    /// @notice empty test to skip file in coverage
    function test_emptyTest() public {}
}
