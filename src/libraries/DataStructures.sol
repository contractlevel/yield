// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IYieldPeer} from "../interfaces/IYieldPeer.sol";

/// @notice This library handles building deposit and withdraw data structures for the Yield system
library DataStructures {
    /// @notice Builds a DepositData struct
    /// @param depositor The address of the depositor
    /// @param amount The amount of USDC to deposit
    /// @param chainSelector The CCIP chain selector of the chain the deposit originated from
    /// @return depositData The DepositData struct
    function buildDepositData(address depositor, uint256 amount, uint64 chainSelector)
        internal
        pure
        returns (IYieldPeer.DepositData memory)
    {
        return IYieldPeer.DepositData({
            depositor: depositor,
            amount: amount,
            totalValue: 0, // This will be set by the strategy chain
            shareMintAmount: 0, // This will be set by the parent chain
            chainSelector: chainSelector
        });
    }

    /// @notice Builds a WithdrawData struct
    /// @param withdrawer The address of the withdrawer
    /// @param shareBurnAmount The amount of shares that were burned to withdraw USDC
    /// @param chainSelector The CCIP chain selector of the chain the withdrawal originated from
    /// @return withdrawData The WithdrawData struct
    function buildWithdrawData(address withdrawer, uint256 shareBurnAmount, uint64 chainSelector)
        internal
        pure
        returns (IYieldPeer.WithdrawData memory)
    {
        return IYieldPeer.WithdrawData({
            withdrawer: withdrawer,
            shareBurnAmount: shareBurnAmount,
            usdcWithdrawAmount: 0, // This will be set by the strategy chain
            totalShares: 0, // This will be set by the parent chain
            chainSelector: chainSelector
        });
    }
}
