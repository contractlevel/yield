# New Invariants Plan

## Backburner (requires infrastructure changes — out of scope for this task)

These are worth exploring in a future task:

1. **Pause/unpause behaviour** — add handler actions for `emergencyPauser` / `emergencyUnpauser`; assert deposits and withdrawals revert while paused
2. **Fix `ghost_totalUsdcWithdrawn`** — currently declared in `Ghosts.t.sol` but never updated in the handler; once fixed, enables exact USDC conservation checks
3. **CCIP tx type integrity** — assert that each `CCIPMessageSent` tx type corresponds to the correct expected protocol message type
4. **Per-peer USDC balance granularity** — track and assert USDC balances at each peer individually rather than system-wide
5. **DepositForwardedToStrategy / WithdrawForwardedToStrategy** amount invariants — ghost tracking exists but no invariants yet
6. **Child PingPong amounts** — `ghost_child_event_DepositPingPongToParent_param_amount_totalSum` and `ghost_parent_event_DepositPingPongToChild_param_amount_totalSum` are tracked but unused in invariants
