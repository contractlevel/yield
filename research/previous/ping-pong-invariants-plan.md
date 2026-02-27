# PingPong Invariants Implementation Plan

> Branch: `fix/adapter-withdraw-checks`
> Date: 2026-02-27

## Background

`MockCCIPRouter.ccipSend` delivers messages synchronously within the same call frame. Zeroing the strategy adapter and triggering a deposit creates infinite recursion (child → parent → child → ...) that hits the EVM call depth limit, reverts, and is silently swallowed by `fail_on_revert`. No events are captured and the invariant cannot be tested.

`ManualMockRouter` solves this with a lazy FIFO queue. When `s_lazyMode == true`, `ccipSend` escrows tokens and enqueues the message instead of delivering. `routeNext()` delivers exactly one message from the front of the queue. This gives the handler a gap between hops to restore adapter state.

---

## Hop Sequences

Adapter restore always happens after exactly 2 `routeNext()` calls. The remaining hops are drained with `while (router.queueLength() > 0) router.routeNext()`.

### D1 — deposit from child, parent is strategy (4 hops total)
1. child → parent (DepositToParent): parent sees adapter == 0, queues pingpong
2. parent → child (DepositPingPong): child retries, queues msg
   **[RESTORE adapter on parent]**
3. child → parent (DepositToParent retry): parent deposits to strategy, queues callback
4. parent → child (DepositCallbackChild): **SharesMinted emitted**

### D2 — deposit from child, child is strategy (6 hops total)
1. depositing\_child → parent (DepositToParent): parent forwards to strategy\_child
2. parent → strategy\_child (DepositToStrategy): strategy\_child sees adapter == 0, queues pingpong
   **[RESTORE adapter on strategy\_child]**
3. strategy\_child → parent (DepositPingPong): parent re-forwards to strategy\_child
4. parent → strategy\_child (DepositToStrategy retry): strategy\_child deposits, queues callback
5. strategy\_child → parent (DepositCallbackParent): parent computes shares, sends to depositing chain
6. parent → depositing\_child (DepositCallbackChild): **SharesMinted emitted**

### W1 — withdraw from child, parent is strategy (4 hops total)
1. child → parent (WithdrawToParent): parent sees adapter == 0, queues pingpong
2. parent → child (WithdrawPingPong): child retries, queues msg
   **[RESTORE adapter on parent]**
3. child → parent (WithdrawPingPong retry): parent withdraws from strategy, queues callback
4. parent → child (WithdrawCallback, with USDC): **WithdrawCompleted emitted**

### W2 — withdraw from child, child is strategy (6 hops total)
1. withdrawing\_child → parent (WithdrawToParent): parent forwards to strategy\_child, adapter == 0
2. parent → strategy\_child (WithdrawToStrategy): strategy\_child sees adapter == 0, queues pingpong
   **[RESTORE adapter on strategy\_child]**
3. strategy\_child → parent (WithdrawPingPong): parent re-forwards to strategy\_child
4. parent → strategy\_child (WithdrawToStrategy retry): strategy\_child withdraws, queues callback
5. strategy\_child → parent (WithdrawCallback, with USDC): parent queues USDC transfer to withdrawer chain
6. parent → withdrawing\_child (WithdrawCallback, with USDC): **WithdrawCompleted emitted**

Note: for W2a (strategy\_child == withdrawing\_child), step 6 goes back to the same child. Logic is identical.

---

## Step 1 — `test/mocks/ManualMockRouter.sol`

Standalone contract. No inheritance from `MockCCIPRouter` (ccipSend is not virtual). Implements `IRouterClient` only.

### Key imports
```solidity
import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
```

### Storage
```solidity
struct QueuedMessage {
    address receiver;
    address sender;
    uint64 sourceChainSelector;
    bytes32 mockMsgId;
    Client.EVM2AnyMessage message;
}

QueuedMessage[] private s_queue;
mapping(address peer => uint64 chainSelector) private s_peerToChainSelector;
bool private s_lazyMode;
```

### `ccipSend` — lazy mode
1. Validate `message.receiver.length == 32`
2. Decode: `address receiver = abi.decode(message.receiver, (address))`
3. Compute: `bytes32 mockMsgId = keccak256(abi.encode(message))`
4. Escrow tokens: `IERC20(token).safeTransferFrom(msg.sender, address(this), amount)` for each tokenAmount
5. Enqueue: `s_queue.push(QueuedMessage({receiver, sender: msg.sender, sourceChainSelector: s_peerToChainSelector[msg.sender], mockMsgId, message}))`
6. Return `mockMsgId`

### `ccipSend` — normal mode
1. Same receiver decode and mockMsgId computation
2. Transfer tokens directly: `IERC20(token).safeTransferFrom(msg.sender, receiver, amount)`
3. Build `executableMsg` (see below) and call `IAny2EVMMessageReceiver(receiver).ccipReceive(executableMsg)` directly
4. Return `mockMsgId`

### `routeNext()`
```
require(s_queue.length > 0)
QueuedMessage memory queued = s_queue[0]
// shift queue (pop front)
for (uint256 i = 0; i < s_queue.length - 1; i++) s_queue[i] = s_queue[i + 1];
s_queue.pop();

// release escrowed tokens to receiver
for each tokenAmount: IERC20(token).safeTransfer(queued.receiver, amount)

// build and deliver
Client.Any2EVMMessage memory executableMsg = Client.Any2EVMMessage({
    messageId: queued.mockMsgId,
    sourceChainSelector: queued.sourceChainSelector,
    sender: abi.encode(queued.sender),
    data: queued.message.data,
    destTokenAmounts: queued.message.tokenAmounts
});
IAny2EVMMessageReceiver(queued.receiver).ccipReceive(executableMsg);
```

`s_lazyMode` stays ON during `routeNext()` — any new sends from within `ccipReceive` are queued, not delivered.

### Additional public functions
```solidity
function getFee(uint64, Client.EVM2AnyMessage memory) public pure returns (uint256) { return 0; }
function isChainSupported(uint64) external pure returns (bool) { return true; }
function getSupportedTokens(uint64) external pure returns (address[] memory) { return new address[](0); }
function setPeerToChainSelector(address peer, uint64 chainSelector) external { ... }
function setLazyMode(bool lazy) external { s_lazyMode = lazy; }
function queueLength() external view returns (uint256) { return s_queue.length; }
```

---

## Step 2 — `test/invariant/modules/Ghosts.t.sol`

Add four new ghosts for PingPong completion tracking:

```solidity
// --- PingPong completion tracking --- //
uint256 public ghost_depositPingPong_calls;
uint256 public ghost_depositPingPong_completions;
uint256 public ghost_withdrawPingPong_calls;
uint256 public ghost_withdrawPingPong_completions;
```

---

## Step 3 — `test/invariant/Handler.t.sol`

### Import
```solidity
import {ManualMockRouter} from "../mocks/ManualMockRouter.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";
```

### Field replacement
Replace `address internal ccipRouter` with `ManualMockRouter internal router`.

Add `using stdStorage for StdStorage;` if not already present.

### Constructor signature
Replace `address _ccipRouter` with `ManualMockRouter _router`. Update body: `router = _router`.

### `depositPingPong` handler

```solidity
function depositPingPong(uint256 addressSeed, uint256 depositAmount, uint256 childSeed) public {
    address depositor = _seedToAddress(addressSeed);
    depositAmount = bound(depositAmount, MIN_DEPOSIT_AMOUNT, MAX_DEPOSIT_AMOUNT);
    deal(address(usdc), depositor, depositAmount);

    address depositingPeer = childSeed % 2 == 0 ? address(child1) : address(child2);

    IYieldPeer.Strategy memory strategy = parent.getStrategy();
    address strategyPeer = chainSelectorsToPeers[strategy.chainSelector];
    address oldAdapter = IYieldPeer(strategyPeer).getActiveStrategyAdapter();
    if (oldAdapter == address(0)) return; // adapter already zero — nothing to test

    stdstore.target(strategyPeer).sig("getActiveStrategyAdapter()").checked_write(address(0));

    router.setLazyMode(true);
    vm.recordLogs();
    _deposit(depositor, depositAmount, depositingPeer);

    router.routeNext();
    router.routeNext();
    stdstore.target(strategyPeer).sig("getActiveStrategyAdapter()").checked_write(oldAdapter);
    while (router.queueLength() > 0) router.routeNext();

    router.setLazyMode(false);

    uint256 prevMinted = ghost_yieldPeer_event_SharesMinted_emissions;
    _handleLogs();
    _updateDepositStateGhosts(depositor, depositAmount);
    ghost_depositPingPong_calls++;
    if (ghost_yieldPeer_event_SharesMinted_emissions > prevMinted) ghost_depositPingPong_completions++;
}
```

### `withdrawPingPong` handler

```solidity
function withdrawPingPong(
    uint256 addressSeed,
    uint256 shareBurnAmount,
    uint256 childSeed,
    uint256 usdcDepositAmount
) public {
    _dealPoolsUsdc();

    address withdrawer = _createOrGetUser(addressSeed);
    if (share.balanceOf(withdrawer) == 0) {
        withdrawer = deposit(true, addressSeed, usdcDepositAmount, childSeed);
    }
    uint256 withdrawerShareBalance = share.balanceOf(withdrawer);
    shareBurnAmount = bound(shareBurnAmount, 1, withdrawerShareBalance);

    address withdrawingPeer = childSeed % 2 == 0 ? address(child1) : address(child2);

    IYieldPeer.Strategy memory strategy = parent.getStrategy();
    address strategyPeer = chainSelectorsToPeers[strategy.chainSelector];
    address oldAdapter = IYieldPeer(strategyPeer).getActiveStrategyAdapter();
    if (oldAdapter == address(0)) return; // adapter already zero — nothing to test

    stdstore.target(strategyPeer).sig("getActiveStrategyAdapter()").checked_write(address(0));

    router.setLazyMode(true);
    vm.recordLogs();

    _changePrank(withdrawer);
    share.transferAndCall(withdrawingPeer, shareBurnAmount, "");
    _stopPrank();

    router.routeNext();
    router.routeNext();
    stdstore.target(strategyPeer).sig("getActiveStrategyAdapter()").checked_write(oldAdapter);
    while (router.queueLength() > 0) router.routeNext();

    router.setLazyMode(false);

    uint256 prevWithdrawCompleted = ghost_yieldPeer_event_WithdrawCompleted_emissions;
    _handleLogs();
    _updateWithdrawStateGhosts(withdrawer, shareBurnAmount);
    ghost_withdrawPingPong_calls++;
    if (ghost_yieldPeer_event_WithdrawCompleted_emissions > prevWithdrawCompleted) {
        ghost_withdrawPingPong_completions++;
    }
}
```

---

## Step 4 — `test/invariant/Invariant.t.sol`

### New field
```solidity
ManualMockRouter internal router;
```

### New import
```solidity
import {ManualMockRouter} from "../mocks/ManualMockRouter.sol";
```

### `_deployInfra` — at the very top, before peers are deployed
```solidity
router = new ManualMockRouter();
```

Replace all `networkConfig.ccip.ccipRouter` peer constructor arguments with `address(router)`.

### `_setCrossChainPeers`
Replace the three `MockCCIPRouter(networkConfig.ccip.ccipRouter).setPeerToChainSelector(...)` calls with:
```solidity
router.setPeerToChainSelector(address(parent), PARENT_SELECTOR);
router.setPeerToChainSelector(address(child1), CHILD1_SELECTOR);
router.setPeerToChainSelector(address(child2), CHILD2_SELECTOR);
```

Remove the `MockCCIPRouter` import if it is no longer used.

### Handler constructor call in `setUp`
Replace `networkConfig.ccip.ccipRouter` with `address(router)` (or pass `router` typed if constructor is updated to accept `ManualMockRouter`).

### Extend `selectors` array and add new entries
```solidity
bytes4[] memory selectors = new bytes4[](7);
// existing 5 selectors...
selectors[5] = Handler.depositPingPong.selector;
selectors[6] = Handler.withdrawPingPong.selector;
```

### Two new invariants
```solidity
function invariant_depositPingPong_alwaysCompletes() public view {
    assertEq(
        handler.ghost_depositPingPong_calls(),
        handler.ghost_depositPingPong_completions(),
        "Invariant violated: Every fuzzed depositPingPong must result in SharesMinted"
    );
}

function invariant_withdrawPingPong_alwaysCompletes() public view {
    assertEq(
        handler.ghost_withdrawPingPong_calls(),
        handler.ghost_withdrawPingPong_completions(),
        "Invariant violated: Every fuzzed withdrawPingPong must result in WithdrawCompleted"
    );
}
```

---

## Implementation Order

1. `test/mocks/ManualMockRouter.sol` — implement and verify it compiles
2. `test/invariant/modules/Ghosts.t.sol` — add 4 new ghost variables
3. `test/invariant/Handler.t.sol` — swap ccipRouter field + constructor, add both handler functions
4. `test/invariant/Invariant.t.sol` — deploy router, update _deployInfra and _setCrossChainPeers, add invariants and selectors
5. Run `forge build` to confirm no compilation errors
6. Run `forge test --match-contract Invariant` to confirm all existing invariants still pass
7. Run `forge coverage` as final check

---

## Key Design Decisions (from Q&A)

| Decision | Choice |
|---|---|
| Inheritance from MockCCIPRouter | No — standalone contract; ccipSend is not virtual |
| File location | `test/mocks/ManualMockRouter.sol` |
| Queue order | FIFO |
| Lazy mode during routeNext | Stays ON — new sends from ccipReceive are also queued |
| mockMsgId generation | `keccak256(abi.encode(message))` — same as MockCCIPRouter, stored at queue time |
| Token handling (lazy mode) | escrow peer→router at queue time; router→receiver at routeNext time |
| ccipReceive delivery | Direct call — no gas-exact (`_callWithExactGasSafeReturnData`) |
| Receiver decoding | `abi.decode(message.receiver, (address))` |
| Adapter zeroing | stdstore |
| Restore point | After exactly 2 explicit routeNext() calls |
| Initiation chain | Always a child (child1 or child2, randomised by seed) |
| Share handling | Single share contract — cross-chain transfer simulated silently |
| Selector weight | All equal (no duplication) |
