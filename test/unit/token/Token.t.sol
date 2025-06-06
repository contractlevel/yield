// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";
import {Client, IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract TokenTest is BaseTest {
    function test_yield_token_setCCIPAdmin() public {
        /// @dev arrange
        _changePrank(baseShare.owner());
        address newAdmin = makeAddr("newAdmin");

        /// @dev act
        baseShare.setCCIPAdmin(newAdmin);

        /// @dev assert
        assertEq(baseShare.getCCIPAdmin(), newAdmin);
    }

    function test_yield_token_crossChainTransfer() public {
        /// @dev arrange
        _selectFork(baseFork);
        deal(address(baseUsdc), holder, DEPOSIT_AMOUNT);
        _changePrank(holder);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        address link = baseParentPeer.getLink();
        address ccipRouter = baseNetworkConfig.ccip.ccipRouter;

        /// @dev sanity check
        uint256 tokenAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.totalSupply(), tokenAmount);

        /// @dev build CCIP message
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: address(baseShare), amount: tokenAmount});
        baseShare.approve(ccipRouter, tokenAmount);

        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(address(holder)),
            data: "",
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(Client.GenericExtraArgsV2({gasLimit: 1000000, allowOutOfOrderExecution: true})),
            feeToken: link
        });

        uint256 ccipFees = IRouterClient(ccipRouter).getFee(optChainSelector, evm2AnyMessage);

        deal(link, holder, ccipFees);
        LinkTokenInterface(link).approve(ccipRouter, ccipFees);
        /// @dev act
        IRouterClient(ccipRouter).ccipSend(optChainSelector, evm2AnyMessage);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert
        assertEq(optShare.balanceOf(holder), tokenAmount);
    }
}
