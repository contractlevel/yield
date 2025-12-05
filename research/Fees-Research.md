
## Beefy Finance

### Fee Structure

- **Performance Fee**: 4.5% on profits (legacy vaults) or 9.5% on top-performing vaults
- **Withdrawal Fee**: 0.1% to discourage short-term withdrawals, that potentially avoid the harvest

### Key Characteristics

- **Harvest on Deposit**: In Strategies deployed to inexpensive chains, the harvest is called together with a user deposit
- **Automated Compounding**: Vaults harvest and reinvest rewards multiple times daily
- **Standalone Contracts**: Each vault is a standalone contract, ChildPeers could mimic this
- **Governance**: Beefy DAO coordinates fee changes, though most are set to fee_max (9.5%)

### Implementation Notes

- Fees are charged on **harvested profits** (performance-based)
- Withdrawal fee is a **one-time fee** on exit
- HarvestOnDeposit doesn't include a withdrawal fee. `https://docs.beefy.finance/beefy-products/vaults#what-is-harvesting-on-deposit`
- As transaction fees on Ethereum are expensive, Beefy handles it by: TVL < $100k ? harvest/3days : harvest/15days and doesn't use HarvestOnDeposit. (maybe socialize this?)
- Also employs Gelato off-chain Resolver to enforce gas rules, this can be another use case for CRE
- `https://docs.beefy.finance/developer-documentation/strategy-contract#harvest`

### Technical Approach

- Implements strategy-specific contracts for interactions with Strategies
- Each contract has \_harvest(address callFeeRecipient) and chargeFees(address callFeeRecipient) functions
- For AAVE: `https://github.com/beefyfinance/beefy-contracts/blob/master/contracts/archive/strategies/Aave/StrategyAave.sol`

```javascript
 // compounds earnings and charges performance fee
    function _harvest(address callFeeRecipient) internal whenNotPaused {
        address[] memory assets = new address[](2);
        assets[0] = aToken;
        assets[1] = varDebtToken;
        IAaveV3Incentives(incentivesController).claimRewards(assets, type(uint).max, address(this), native);

        uint256 nativeBal = IERC20(native).balanceOf(address(this));
        if (nativeBal > 0) {
            chargeFees(callFeeRecipient);
            swapRewards();
            uint256 wantHarvested = availableWant();
            deposit();

            lastHarvest = block.timestamp;
            emit StratHarvest(msg.sender, wantHarvested, balanceOf());
        }
    }

    // performance fees
    function chargeFees(address callFeeRecipient) internal {
        uint256 nativeFeeBal = IERC20(native).balanceOf(address(this)).mul(45).div(1000);

        uint256 callFeeAmount = nativeFeeBal.mul(callFee).div(MAX_FEE);
        IERC20(native).safeTransfer(callFeeRecipient, callFeeAmount);

        uint256 beefyFeeAmount = nativeFeeBal.mul(beefyFee).div(MAX_FEE);
        IERC20(native).safeTransfer(beefyFeeRecipient, beefyFeeAmount);

        uint256 strategistFeeAmount = nativeFeeBal.mul(STRATEGIST_FEE).div(MAX_FEE);
        IERC20(native).safeTransfer(strategist, strategistFeeAmount);

        emit ChargedFees(callFeeAmount, beefyFeeAmount, strategistFeeAmount);
    }

    // swap rewards to {want}
    function swapRewards() internal {
        uint256 nativeBal = IERC20(native).balanceOf(address(this));
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(nativeBal, 0, nativeToWantRoute, address(this), now);
    }

```

---

## Yearn Finance

### Fee Structure (V2)

- **Management Fee**: 2% annually (NEW in V2)
- **Performance Fee**: 20% on profits (10% in V3)
- **Withdrawal Fee**: Removed in V2 (was configurable in V1)

### Key Characteristics

- **Multi-strategy Vaults**: Vaults employ multiple strategies simultaneously (makes it simpler for our case)
- **Dynamic Reallocation**: Automatically moves funds to most profitable strategies
- **Gas-efficient**: Socializes gas costs for compounding

### Implementation Notes

- **Performance Fee**: Deducted from yield earned every time a vault harvests a strategy.

- **Management Fee**: Flat rate taken from vault deposits over a year. The fee is extracted by minting new shares of the vault, thereby diluting vault participants. This is done at the time of harvest, and calculated based on time since the previous harvest.

### Technical Approach

https://github.com/yearn/yearn-vaults-v3/blob/104a2b233bc6d43ba40720d68355b04d2dc31795/contracts/VaultV3.vy#L1115

V3
```python

# If we have fees then get the proportional amount of shares to issue.
        if total_fees > 0:
            # Get the total amount shares to issue for the fees.
            total_fees_shares = shares_to_burn * total_fees / (loss + total_fees)

            # Get the protocol fee config for this vault.
            protocol_fee_bps, protocol_fee_recipient = IFactory(self.factory).protocol_fee_config()

            # If there is a protocol fee.
            if protocol_fee_bps > 0:
                # Get the percent of fees to go to protocol fees.
                protocol_fees_shares = total_fees_shares * convert(protocol_fee_bps, uint256) / MAX_BPS


# Issue shares for fees that were calculated above if applicable.
    if total_fees_shares > 0:
        # Accountant fees are (total_fees - protocol_fees).
        self._issue_shares(total_fees_shares - protocol_fees_shares, accountant)

        # If we also have protocol fees.
        if protocol_fees_shares > 0:
            self._issue_shares(protocol_fees_shares, protocol_fee_recipient)

    # We have to recalculate the fees paid for cases with an overall loss or no profit locking
    if loss + total_fees > gain + total_refunds or profit_max_unlock_time == 0:
        total_fees = self._convert_to_assets(total_fees_shares, Rounding.ROUND_DOWN)

```


V2: 
`https://github.com/yearn/yearn-vaults/blob/7e0718b709d38769700bd458381e1b19ea8e67ca/contracts/Vault.vy#L1634`

**AssessFees and Report Functions**

```python
def _assessFees(strategy: address, gain: uint256) -> uint256:
    # Issue new shares to cover fees
    # NOTE: In effect, this reduces overall share price by the combined fee
    # NOTE: may throw if Vault.totalAssets() > 1e64, or not called for more than a year
    if self.strategies[strategy].activation == block.timestamp:
        return 0  # NOTE: Just added, no fees to assess

    duration: uint256 = block.timestamp - self.strategies[strategy].lastReport
    assert duration != 0 #dev: can't call assessFees twice within the same block

    if gain == 0:
        # NOTE: The fees are not charged if there hasn't been any gains reported
        return 0

    management_fee: uint256 = (
        (
            (self.strategies[strategy].totalDebt - Strategy(strategy).delegatedAssets())
            * duration
            * self.managementFee
        )
        / MAX_BPS
        / SECS_PER_YEAR
    )

    # NOTE: Applies if Strategy is not shutting down, or it is but all debt paid off
    # NOTE: No fee is taken when a Strategy is unwinding it's position, until all debt is paid
    strategist_fee: uint256 = (
        gain
        * self.strategies[strategy].performanceFee
        / MAX_BPS
    )
    # NOTE: Unlikely to throw unless strategy reports >1e72 harvest profit
    performance_fee: uint256 = gain * self.performanceFee / MAX_BPS

    # NOTE: This must be called prior to taking new collateral,
    #       or the calculation will be wrong!
    # NOTE: This must be done at the same time, to ensure the relative
    #       ratio of governance_fee : strategist_fee is kept intact
    total_fee: uint256 = performance_fee + strategist_fee + management_fee
    # ensure total_fee is not more than gain
    if total_fee > gain:
        total_fee = gain
    if total_fee > 0:  # NOTE: If mgmt fee is 0% and no gains were realized, skip
        reward: uint256 = self._issueSharesForAmount(self, total_fee)

        # Send the rewards out as new shares in this Vault
        if strategist_fee > 0:  # NOTE: Guard against DIV/0 fault
            # NOTE: Unlikely to throw unless sqrt(reward) >>> 1e39
            strategist_reward: uint256 = (
                strategist_fee
                * reward
                / total_fee
            )
            self._transfer(self, strategy, strategist_reward)
            # NOTE: Strategy distributes rewards at the end of harvest()
        # NOTE: Governance earns any dust leftover from flooring math above
        if self.balanceOf[self] > 0:
            self._transfer(self, self.rewards, self.balanceOf[self])
    return total_fee




```python
@external
def report(gain: uint256, loss: uint256, _debtPayment: uint256) -> uint256:
    """
    @notice
        Reports the amount of assets the calling Strategy has free (usually in
        terms of ROI).

        The performance fee is determined here, off of the strategy's profits
        (if any), and sent to governance.

        The strategist's fee is also determined here (off of profits), to be
        handled according to the strategist on the next harvest.

        This may only be called by a Strategy managed by this Vault.
    @dev
        For approved strategies, this is the most efficient behavior.
        The Strategy reports back what it has free, then Vault "decides"
        whether to take some back or give it more. Note that the most it can
        take is `gain + _debtPayment`, and the most it can give is all of the
        remaining reserves. Anything outside of those bounds is abnormal behavior.

        All approved strategies must have increased diligence around
        calling this function, as abnormal behavior could become catastrophic.
    @param gain
        Amount Strategy has realized as a gain on it's investment since its
        last report, and is free to be given back to Vault as earnings
    @param loss
        Amount Strategy has realized as a loss on it's investment since its
        last report, and should be accounted for on the Vault's balance sheet.
        The loss will reduce the debtRatio. The next time the strategy will harvest,
        it will pay back the debt in an attempt to adjust to the new debt limit.
    @param _debtPayment
        Amount Strategy has made available to cover outstanding debt
    @return Amount of debt outstanding (if totalDebt > debtLimit or emergency shutdown).
    """

    # Only approved strategies can call this function
    assert self.strategies[msg.sender].activation > 0

    # Check report is within healthy ranges
    if self.healthCheck != ZERO_ADDRESS:
        if HealthCheck(self.healthCheck).doHealthCheck(msg.sender):
            strategy: address  = msg.sender
            _debtOutstanding: uint256 = self._debtOutstanding(msg.sender)
            totalDebt: uint256 = self.strategies[msg.sender].totalDebt

            assert(HealthCheck(self.healthCheck).check(strategy, gain, loss, _debtPayment, _debtOutstanding, totalDebt)) #dev: fail healthcheck
        else:
            strategy: address  = msg.sender
            HealthCheck(self.healthCheck).enableCheck(strategy)

    # No lying about total available to withdraw!
    assert self.token.balanceOf(msg.sender) >= gain + _debtPayment

    # We have a loss to report, do it before the rest of the calculations
    if loss > 0:
        self._reportLoss(msg.sender, loss)

    # Assess both management fee and performance fee, and issue both as shares of the vault
    totalFees: uint256 = self._assessFees(msg.sender, gain)

    # Returns are always "realized gains"
    self.strategies[msg.sender].totalGain += gain

    # Compute the line of credit the Vault is able to offer the Strategy (if any)
    credit: uint256 = self._creditAvailable(msg.sender)

    # Outstanding debt the Strategy wants to take back from the Vault (if any)
    # NOTE: debtOutstanding <= StrategyParams.totalDebt
    debt: uint256 = self._debtOutstanding(msg.sender)
    debtPayment: uint256 = min(_debtPayment, debt)

    if debtPayment > 0:
        self.strategies[msg.sender].totalDebt -= debtPayment
        self.totalDebt -= debtPayment
        debt -= debtPayment
        # NOTE: `debt` is being tracked for later

    # Update the actual debt based on the full credit we are extending to the Strategy
    # or the returns if we are taking funds back
    # NOTE: credit + self.strategies[msg.sender].totalDebt is always < self.debtLimit
    # NOTE: At least one of `credit` or `debt` is always 0 (both can be 0)
    if credit > 0:
        self.strategies[msg.sender].totalDebt += credit
        self.totalDebt += credit

    # Give/take balance to Strategy, based on the difference between the reported gains
    # (if any), the debt payment (if any), the credit increase we are offering (if any),
    # and the debt needed to be paid off (if any)
    # NOTE: This is just used to adjust the balance of tokens between the Strategy and
    #       the Vault based on the Strategy's debt limit (as well as the Vault's).
    totalAvail: uint256 = gain + debtPayment
    if totalAvail < credit:  # credit surplus, give to Strategy
        self.erc20_safe_transfer(self.token.address, msg.sender, credit - totalAvail)
    elif totalAvail > credit:  # credit deficit, take from Strategy
        self.erc20_safe_transferFrom(self.token.address, msg.sender, self, totalAvail - credit)
    # else, don't do anything because it is balanced

    # Profit is locked and gradually released per block
    # NOTE: compute current locked profit and replace with sum of current and new
    lockedProfitBeforeLoss: uint256 = self._calculateLockedProfit() + gain - totalFees
    if lockedProfitBeforeLoss > loss:
        self.lockedProfit = lockedProfitBeforeLoss - loss
    else:
        self.lockedProfit = 0

    # Update reporting time
    self.strategies[msg.sender].lastReport = block.timestamp
    self.lastReport = block.timestamp

    log StrategyReported(
        msg.sender,
        gain,
        loss,
        debtPayment,
        self.strategies[msg.sender].totalGain,
        self.strategies[msg.sender].totalLoss,
        self.strategies[msg.sender].totalDebt,
        credit,
        self.strategies[msg.sender].debtRatio,
    )

    if self.strategies[msg.sender].debtRatio == 0 or self.emergencyShutdown:
        # Take every last penny the Strategy has (Emergency Exit/revokeStrategy)
        # NOTE: This is different than `debt` in order to extract *all* of the returns
        return Strategy(msg.sender).estimatedTotalAssets()
    else:
        # Otherwise, just return what we have as debt outstanding
        return debt 
```

Note: Both Protocols have revenue sharing incentives for their "community" implemented inside their fee harvesting.







What works for YieldCoin:

## Implementation Plan (When Ready)

### Approach: Beefy-Style Harvest on Deposit + CRE Cron

**Harvest Triggers:**

1. **On Deposit** (inexpensive chains):

   - Call harvest when user deposits
   - Collect fees on accumulated yield
   - Reinvest remaining yield

2. **CRE Cron Jobs** (all chains):
   - Regular harvest intervals via CRE
   - Use CRE for gas rule enforcement

**Fee Collection:**

- Performance fee: 10-20% of harvest profits (TBD)
- Collected during harvest operations
- No withdrawal fees

**Yield Calculation:**

- **Primary Approach** (if verified): Use Aave liquidity index formula
  - Formula: `(scaledBalance * liquidityIndex * tokenDecimals) / 1e27`
  - Track `scaledBalance` and `liquidityIndex` at deposit
  - Calculate yield: `currentBalance - originalDeposit`
- **Fallback Approach**: Track principal separately
  - Calculate yield: `currentBalance - principal`
- Apply fee to yield portion only



### Implementation Requirements

**Definite Requirements:**

1. **Harvest Function**: Implement `harvest()` that:

   - Claims rewards from strategy
   - Calculates yield using liquidity index
   - Applies performance fee
   - Reinvests remaining yield

2. **Harvest on Deposit**: Modify deposit flow to trigger harvest (on inexpensive chains)

3. **CRE Integration**: Set up CRE cron jobs for regular harvesting

   - TVL-based intervals
   - Gas rule enforcement via CRE

4. **Liquidity Index Tracking** (If Verified):

   - Verify exact formula from Aave aToken contract code first
   - Store `scaledBalance` and `liquidityIndex` at deposit time
   - Query current `liquidityIndex`/`normalizedIncome` from Aave when calculating yield
   - Calculate yield using verified formula
   - **Alternative**: If verification fails, use principal tracking method (simpler fallback)

5. **Fee Collection**:
   - Collect performance fee during harvest
   - Store fees in contract (withdrawable by authorized role)


**State Variables Needed:**



**Functions Needed:**

```javascript
function harvest() external; // Main harvest function

function _calculateYield(address asset) internal view returns (uint256);

function _collectPerformanceFee(uint256 yield) internal returns (uint256);

```


### Key Design Decisions Needed

1. Performance fee rate (10%? 20%? Variable by TVL?)
2. Harvest on deposit: Which chains? (gas cost threshold?)
3. CRE cron intervals: TVL thresholds and frequencies
4. Fee withdrawal: Per stablecoin or aggregated?



## References

- Beefy Harvest on Deposit: https://docs.beefy.finance/beefy-products/vaults#what-is-harvesting-on-deposit
- Beefy Harvest Documentation: https://docs.beefy.finance/developer-documentation/strategy-contract#harvest





Notes during research:


- Beefy uses harvest(), additional functionality: reaps rewards, applies fees, reinvests (compounds) rewards to strategy immediately.
  we can use this as an additional approach to tackle the "strategy rarely changes" issue
  For the rare vaults which do not Harvest on Deposit, they assign a withdrawal fee of up to 0.1% to each vault to protect bad actors from abusing the vaults with too much flipping.
  up to 9% performance on harvest

- Yearn v2 uses performance & management fees. They implement both by printing new shares to the treasury, dilluting price per share slightly each time.
  Once a strategy is harvested, the gains are distributed during 6 hours. This is to prevent sandwich attacks of an account depositing tokens right before the harvest and withdrawing right after and getting the profits without staying in the vault.
  2% management, 20% performance, really only mentioned in DAO proposal and x.com. big sus
  You can retrieve both the default protocol fee as well as if a custom config has been set for a specific vault or strategy using the Vault Factory that corresponds to that vault's API.

```python
#Retrieve the default config.

vaultFactory.protocol_fee_config()

#Check a specific vault current config to be used

vaultFactory.protocol_fee_config(vault_address)
```


- liquidity index to calculate exact yield for a given deposit
  The core calculation involves the scaledBalance of the user and the reserve's liquidityIndex: Retrieve the liquidityIndex: This index is a global accumulator for the interest rate of a specific reserve since the pool's inception. You can get this using the IDataProvider.getReserveData(asset_address) function from the Aave protocol's data provider contract.Retrieve the user's scaledBalance: This represents the user's balance excluding the accrued interest. You can get this by calling AToken(asset_address).scaledBalanceOf(user_address).Calculate the current value: The user's current, actual balance (principal + yield) can be calculated using the formula:Final Value = (scaledBalance _ liquidityIndex _ 1e18) / 1e27
  Yield = Final Value - Original Deposit is to handle the specific precision (RAY math) used in Aave's smart contracts. By comparing the current balance calculated this way with the user's initial deposit, you can determine the exact amount of yield generated. For ongoing tracking, the @aave/math-utils package provides formatter functions to compute cumulative metrics from on-chain data

- look up the actual yield of a deposit, continuous or not on a protocol like aave or compound
- ask chainlink for totalShares tracker across chains
- ask chainlink for workflows queuing up and using last workflows returns