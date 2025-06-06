// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BurnMintTokenPool, IBurnMintERC20} from "@chainlink/contracts/src/v0.8/ccip/pools/BurnMintTokenPool.sol";
import {IERC677Receiver} from "@chainlink/contracts/src/v0.8/shared/interfaces/IERC677Receiver.sol";
import {Pool} from "@chainlink/contracts/src/v0.8/ccip/libraries/Pool.sol";

contract SharePool is BurnMintTokenPool {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error SharePool__OnlyShare();
    error SharePool__ChainNotAllowed(uint64 chainSelector);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param shareToken The SHARE token contract for this chain
    /// @param rmnProxy The Risk Management Network proxy address
    /// @param ccipRouter The CCIP router address
    constructor(IBurnMintERC20 shareToken, address rmnProxy, address ccipRouter)
        BurnMintTokenPool(shareToken, 18, new address[](0), rmnProxy, ccipRouter)
    {}

    // /*//////////////////////////////////////////////////////////////
    //                             EXTERNAL
    // //////////////////////////////////////////////////////////////*/
    // /// @notice transferAndCall SHAREs to this contract to move them across chains
    // /// @param sender The address that transferred the SHAREs
    // /// @param amount The amount of SHAREs transferred
    // /// @param data This should decode to the destination chain selector
    // /// @dev Revert if the msg.sender is not the SHARE token
    // /// @dev Revert if the destination chain selector is not allowed
    // function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external {
    //     if (msg.sender != address(i_token)) revert SharePool__OnlyShare();

    //     uint64 remoteChainSelector = abi.decode(data, (uint64));

    //     if (!isSupportedChain(remoteChainSelector)) revert SharePool__ChainNotAllowed(remoteChainSelector);

    //     Pool.LockOrBurnInV1 memory lockOrBurnIn = _buildTransferData(sender, amount, remoteChainSelector);

    //     _validateLockOrBurn(lockOrBurnIn);

    //     _burn(lockOrBurnIn.amount);

    //     emit Burned(sender, amount);

    //     // emit LockOrBurnOutV1({
    //     //     destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector),
    //     //     destPoolData: _encodeLocalDecimals()
    //     // });

    //     // return Pool.LockOrBurnOutV1({
    //     //     destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector),
    //     //     destPoolData: _encodeLocalDecimals()
    //     // });
    // }

    // /*//////////////////////////////////////////////////////////////
    //                             INTERNAL
    // //////////////////////////////////////////////////////////////*/
    // /// @notice Builds the transfer data for the lockOrBurn function
    // /// @param sender The address that transferred the SHAREs
    // /// @param amount The amount of SHAREs transferred
    // /// @param remoteChainSelector The destination chain selector
    // /// @return The transfer data for the lockOrBurn function
    // function _buildTransferData(address sender, uint256 amount, uint64 remoteChainSelector)
    //     internal
    //     view
    //     returns (Pool.LockOrBurnInV1 memory)
    // {
    //     return Pool.LockOrBurnInV1({
    //         receiver: abi.encode(sender),
    //         remoteChainSelector: remoteChainSelector,
    //         originalSender: sender,
    //         amount: amount,
    //         localToken: address(i_token)
    //     });
    // }
}
