# Testing

The testing process looks like this:

1. unit tests
2. static analysis
3. invariant tests
4. certora formal verification
5. mutation testing
6. @review

**Clear cache before running new tests:**

```
forge clean
```

**Run Foundry tests:**

```
forge test
```

- [Testing](#testing)
- [Commands](#commands)
  - [Unit tests](#unit-tests)
  - [Static analysis](#static-analysis)
  - [Invariant tests](#invariant-tests)
  - [Certora formal verification](#certora-formal-verification)
  - [Mutation tests](#mutation-tests)
- [Process](#process)
  - [Unit tests](#unit-tests-1)
  - [Static analysis](#static-analysis-1)
  - [Invariant tests](#invariant-tests-1)
  - [Certora formal verification](#certora-formal-verification-1)
  - [Mutation tests](#mutation-tests-1)
  - [@review](#review)
- [Resources](#resources)
  - [Unit tests](#unit-tests-2)
  - [Static analysis](#static-analysis-2)
  - [Invariant tests](#invariant-tests-2)
  - [Certora formal verification](#certora-formal-verification-2)
  - [Mutation tests](#mutation-tests-2)
- [Go the extra mile](#go-the-extra-mile)

# Commands

## Unit tests

**Run unit tests:**

```
forge test --mt test_yield
```

**See unit coverage:**

```
forge coverage
```

**Debug coverage:**

```
forge coverage --report debug
```

## Static analysis

**Run Slither:**

```
slither . --filter-path lib
```

**Run Aderyn:**

```
aderyn .
```

## Invariant tests

**Run Foundry invariant tests:**

```
forge test --mt invariant
```

## Certora formal verification

These don't have to all be run at the same time, but should all be run at least once _and passing_ at the end of each task.

**Run Certora specs:**

```
certoraRun ./certora/conf/child/BaseChild.conf
certoraRun ./certora/conf/parent/BaseParent.conf
certoraRun ./certora/conf/parent/Parent.conf
certoraRun ./certora/conf/child/Child.conf
certoraRun ./certora/conf/Yield.conf
certoraRun ./certora/conf/modules/Rebalancer.conf --nondet_difficult_funcs
certoraRun ./certora/conf/adapters/AaveV3Adapter.conf
certoraRun ./certora/conf/adapters/CompoundV3Adapter.conf
certoraRun ./certora/conf/modules/StrategyRegistry.conf
```

## Mutation tests

All of these shouldn't be run at the same time - only the ones that are relevant to the contracts that have been refactored/added in the current task. The contract to mutate should be specified in the `.conf` file.

**Run Certora mutate:**

```
certoraMutate ./certora/conf/child/BaseChild.conf
certoraMutate ./certora/conf/parent/BaseParent.conf
certoraMutate ./certora/conf/parent/Parent.conf
certoraMutate ./certora/conf/child/Child.conf
certoraMutate ./certora/conf/Yield.conf
certoraMutate ./certora/conf/modules/Rebalancer.conf --nondet_difficult_funcs
certoraMutate ./certora/conf/adapters/AaveV3Adapter.conf
certoraMutate ./certora/conf/adapters/CompoundV3Adapter.conf
certoraMutate ./certora/conf/modules/StrategyRegistry.conf
```

# Process

## Unit tests

The `BaseTest.t.sol` sets up the test suite. The unit tests are generally structured so that each folder is a specific contract, such as `parentPeer`, or a group of similar, less significant contracts, such as `mocks`.

Individual files are generally for a single function.

Naming convention is:

```
test_yield_CONTRACT_FUNCTION_ACTION_CONDITION

// example:
test_yield_parentPeer_setInitialActiveStrategy_revertsWhen_notOwner
```

This makes running similar tests easier. Each of the following tests will run all matching names:

```
forge test --mt test_yield_parentPeer
forge test --mt test_yield_parentPeer_setInitialActiveStrategy
forge test --mt test_yield_parentPeer_setInitialActiveStrategy_revertsWhen
```

_MENTION CANNOTEXECUTE MODIFIER AND CHECKLOG TEST_

## Static analysis

Every individual output should be reviewed.

## Invariant tests

Invariant tests run on Foundry's locally deployed infrastructure, as opposed to forked mainnets like our unit tests. This is because calls of forked mainnets are done via rpc providers, which have limits. Invariant fuzz runs will perform thousands of calls, so we would hit that limit very quickly.

Invariants are defined as mathematical expressions in `Invariant.t.sol`. When we run each invariant test, we are asserting this expression holds true between fuzz runs.

## Certora formal verification

`Rebalancer.conf` will have some vacuous output.

_MENTION EVENT, GHOST, HOOK FORMATTING_

All events should be defined in their relevant spec as so:

```
definition ShareMintUpdateEvent() returns bytes32 =
// keccak256(abi.encodePacked("ShareMintUpdate(uint256,uint64,uint256)"))
    to_bytes32(0xb72631492a31c565f552fa60e02d84a245e98d5519ff22100b4cae30bb5d8465);
```

Use `chisel` and paste the keccak256 command with the event signature to get the hash, and then paste that into the to_bytes32() definition. This is the easiest way for the Prover to recognise specific events.

## Mutation tests

Go to the `.conf` file of the contracts added/refactored in the current task and update the filename in the `mutations: gambit` section.

When you run `certoraMutate`, 6 Certora jobs will be created. The first is the original contract (no mutations) and should all pass as expected. The other 5 will have mutations in them. We want at least one rule to fail for each of these 5 mutated runs. Go to the `gambit_out/mutants` directory to see the mutated contracts.

If you can't find the mutant (the artificially introduced bug): search "// a". Replace "a" with every letter on your keyboard until you find it. There should be a comment above the mutant, describing it.

If you are testing the same mutated module/contract against different specs (ie YieldFees against BasePeer.spec, ChildPeer.spec, etc): mutants might be missed if the execution path is not covered by that spec. Please be sure to make sure the same mutant is caught by at least one spec.

If mutants are not caught by any spec, write a new rule to specifically catch it.

If you are not sure whether the Certora job was run on a mutated contract, go to the files tab on the left in the Certora Prover output, and navigate to the appropriate file to review for mutants.

## @review

`// @review` comments are used throughout the codebase during a task. Search the codebase for `@review` and review each comment.

Each review that is relevant for the current task should be addressed.

Some review comments may be for future tasks, so they can be ignored until that task is in progress.

Run test suite, static analysis, and specs again.

# Resources

## Unit tests

## Static analysis

## Invariant tests

Recommended resources on learning invariant testing (after completing Cyfrin courses):

**articles**:

https://medium.com/cyfrin/invariant-testing-enter-the-matrix-c71363dea37e alex roan beanstalk audit

https://github.com/horsefacts/weth-invariant-testing horsefacts weth

https://dacian.me/writing-multi-fuzzer-invariant-tests-using-chimera#heading-thinking-in-invariants dacian chimera

https://dacian.me/find-highs-before-external-auditors-using-invariant-fuzz-testing#heading-thinking-in-invariants dacian invariants

https://justdravee.github.io/posts/the-3-prompts-of-spec-thinking/ bowtieddravee spec thinking

https://justdravee.github.io/posts/list-100-assumptions-prompt/ bowtieddravee assumptions

https://book.getrecon.xyz/writing_invariant_tests/learn_invariant_testing.html getrecon

**videos**:

https://getrecon.xyz/bootcamp getrecon bootcamp

## Certora formal verification

https://dacian.me/find-highs-before-external-auditors-using-certora-formal-verification dacian certora

https://docs.certora.com/en/latest/docs/user-guide/tutorials.html#stanford-defi-security-summit certora stanford defi security

## Mutation tests

https://docs.certora.com/en/latest/docs/gambit/mutation-verifier.html

https://x.com/ChanniGreenwall CEO of Olympix, lots of insightful posts on testing

https://www.youtube.com/watch?v=iqbaf4wrEfE Owen Thurm from Guardian Audits using Olympix for mutation testing

# Go the extra mile

chimera, olympix, 4nlyzer, slither mutate

https://www.youtube.com/watch?v=DRZogmD647U owen thurm advanced security course part 1

https://www.youtube.com/watch?v=zLnxRvf6IMA owen thurm advanced security course part 2
