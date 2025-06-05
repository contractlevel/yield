// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Client, IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IYieldPeer} from "../interfaces/IYieldPeer.sol";

library CCIPOperations {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error CCIPOperations__NotEnoughLink(uint256 linkBalance, uint256 fees);
    error CCIPOperations__InvalidToken(address invalidToken);
    error CCIPOperations__InvalidTokenAmount(uint256 invalidAmount);

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    function _buildCCIPMessage(
        address receiver,
        IYieldPeer.CcipTxType txType,
        bytes memory data,
        Client.EVMTokenAmount[] memory tokenAmounts,
        uint256 gasLimit,
        address link
    ) internal pure returns (Client.EVM2AnyMessage memory evm2AnyMessage) {
        evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(txType, data),
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(Client.GenericExtraArgsV2({gasLimit: gasLimit, allowOutOfOrderExecution: true})),
            feeToken: link
        });
    }

    function _handleCCIPFees(
        address ccipRouter,
        address link,
        uint64 dstChainSelector,
        Client.EVM2AnyMessage memory evm2AnyMessage
    ) internal {
        uint256 fees = IRouterClient(ccipRouter).getFee(dstChainSelector, evm2AnyMessage);
        uint256 linkBalance = LinkTokenInterface(link).balanceOf(address(this));
        if (fees > linkBalance) revert CCIPOperations__NotEnoughLink(linkBalance, fees);
        LinkTokenInterface(link).approve(ccipRouter, fees);
    }

    function _prepareTokenAmounts(IERC20 usdc, uint256 bridgeAmount, address ccipRouter)
        internal
        returns (Client.EVMTokenAmount[] memory tokenAmounts)
    {
        if (bridgeAmount > 0) {
            tokenAmounts = new Client.EVMTokenAmount[](1);
            tokenAmounts[0] = Client.EVMTokenAmount({token: address(usdc), amount: bridgeAmount});
            usdc.approve(ccipRouter, bridgeAmount);
        } else {
            tokenAmounts = new Client.EVMTokenAmount[](0);
        }
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL VIEW
    //////////////////////////////////////////////////////////////*/
    function _validateTokenAmounts(Client.EVMTokenAmount[] memory tokenAmounts, address usdc, uint256 amount)
        internal
        pure
    {
        if (tokenAmounts[0].token != usdc) revert CCIPOperations__InvalidToken(tokenAmounts[0].token);
        if (tokenAmounts[0].amount != amount) revert CCIPOperations__InvalidTokenAmount(tokenAmounts[0].amount);
    }
}
