# Discarded Properties

## YieldFees

### Spec Based Properties
- The function `_calculateFee` should return `0` if `s_feeRate` is `0` - **REASON: Internal function, cannot be tested via external call**

### High Level Properties
- The Fee Rate Divisor should always equal `1_000_000` - **REASON: Trivial constant check, always true by definition (vacuous)**
- The Max Fee Rate should always equal `10_000` - **REASON: Trivial constant check, always true by definition (vacuous)**

## PausableWithAccessControl

### State Transitions
- A contract cannot transition from paused to paused state - **REASON: Obvious/trivial - OpenZeppelin's Pausable already enforces this**
- A contract cannot transition from unpaused to unpaused state - **REASON: Obvious/trivial - OpenZeppelin's Pausable already enforces this**

### High Level Properties
- The Admin Role Transfer Delay should be `259200` seconds (3 days) - **REASON: Trivial constant check, always true by definition (vacuous)**

## StrategyAdapter

### Spec Based Properties
- The immutable `i_yieldPeer` should be set in the constructor and never change - **REASON: Trivial - immutables by definition never change (vacuous)**

## CompoundV3Adapter

### High Level Properties
- The immutable `i_comet` should never change after deployment - **REASON: Trivial - immutables by definition never change (vacuous)**

## AaveV3Adapter

### High Level Properties
- The immutable `i_aavePoolAddressesProvider` should never change after deployment - **REASON: Trivial - immutables by definition never change (vacuous)**

## YieldPeer

### High Level Properties
- The USDC Decimals constant should be `1e6` - **REASON: Trivial constant check, always true by definition (vacuous)**
- The Share Decimals constant should be `1e18` - **REASON: Trivial constant check, always true by definition (vacuous)**
- The Initial Share Precision should be `SHARE_DECIMALS / USDC_DECIMALS` - **REASON: Trivial constant check, always true by definition (vacuous)**
- The conversion from USDC to Share should multiply by `INITIAL_SHARE_PRECISION` - **REASON: Internal function check, cannot be tested via external call**
- The conversion from Share to USDC should divide by `INITIAL_SHARE_PRECISION` - **REASON: Internal function check, cannot be tested via external call**

## ParentPeer

### High Level Properties
- Share Mint Amount should never be `0` (minimum is `1`) - **REASON: This is enforced in internal `_calculateMintAmount` function which cannot be directly tested externally; the property is better captured by testing actual mint operations**
