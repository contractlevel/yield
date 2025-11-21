// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IConceroPeer {
    enum CrossChainTxType {
        DepositToParent, // 0 - deposit from child to parent (to get strategy chain)
        DepositToStrategy, // 1 - deposit from parent to strategy (to deposit to strategy and get totalValue)
        DepositCallbackParent, // 2 - deposit callback from strategy to parent (to calculate shareMintAmount and update totalShares)
        DepositCallbackChild, // 3 - deposit callback from parent to child (to mint shares)
        WithdrawToParent, // 4 - withdraw from child to parent (to get strategy chain and update totalShares)
        WithdrawToStrategy, // 5 - withdraw from parent to strategy (to withdraw from strategy and get usdcWithdrawAmount)
        WithdrawCallback, // 6 - withdraw callback from strategy to withdraw chain (to send USDC to withdrawer)
        RebalanceOldStrategy, // 7 - message from parent to old strategy (to move funds to new strategy)
        RebalanceNewStrategy // 8 - reallocate funds from old strategy to new strategy
    }
}
