// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IYieldPeer {
    struct Strategy {
        uint64 chainSelector;
        Protocol protocol;
    }

    enum Protocol {
        Aave,
        Compound
    }

    enum CcipTxType {
        DepositToParent, // deposit from child to parent (to get strategy chain)
        DepositToStrategy, // deposit from parent to strategy (to deposit to strategy and get totalValue)
        DepositCallbackParent, // deposit callback from strategy to parent (to calculate shareMintAmount and update totalShares)
        DepositCallbackChild, // deposit callback from parent to child (to mint shares)
        WithdrawToParent, // withdraw from child to parent (to get strategy chain and update totalShares)
        WithdrawToStrategy, // withdraw from parent to strategy (to withdraw from strategy and get usdcWithdrawAmount)
        WithdrawCallback, // withdraw callback from strategy to withdraw chain (to send USDC to withdrawer)
        RebalanceOldStrategy, // message from parent to old strategy (to move funds to new strategy)
        RebalanceNewStrategy // reallocate funds from old strategy to new strategy

    }

    struct DepositData {
        address depositor; // user who deposited USDC and will receive shares
        uint256 amount; // amount of USDC deposited // @review do we need this if we have tokenAmounts?
        uint256 totalValue; // total value of the system (this is updated on the strategy chain)
        uint256 shareMintAmount; // amount of shares minted to the depositor (this is updated on the parent chain callback)
        uint64 chainSelector; // chain selector of the chain the deposit originated from
    }

    struct WithdrawData {
        address withdrawer; // user who is withdrawing USDC
        uint256 shareBurnAmount; // amount of shares burned
        uint256 totalShares; // total shares in the system (updated on the parent chain)
        uint256 usdcWithdrawAmount; // amount of USDC to withdraw // @review do we need this if we have tokenAmounts?
        uint64 chainSelector; // chain selector of the chain the withdrawal originated from
    }

    function deposit(uint256 amountToDeposit) external;
    function getStrategyPool() external view returns (address);
    function getTotalValue() external view returns (uint256);
}
