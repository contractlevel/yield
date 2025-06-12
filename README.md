# Contract Level Yield (CLY)

This project is being built for the Chainlink Chromion Hackathon.

## DefiLlama Proxy API

```
cd functions/defillama-proxy
npm i
```

The `function.zip` file located in `functions/defillama-proxy` has been uploaded to AWS Lambda and deployed. This was needed because we are using the DefiLlama API to fetch data about APYs, but the payload response was too large for Chainlink Functions, so we filter on the server side via our proxy API.

## Formal Verification

This project uses Certora for formal verification. A `CERTORAKEY` is required to use the Certora Prover. Get one [here](https://docs.certora.com/en/latest/docs/user-guide/install.html#step-3-set-the-personal-access-key-as-an-environment-variable).

```
export CERTORAKEY=<personal_access_key>
```

The `BasePeer` spec verifies mutual behavior of the Parent and Child Peers, so there are separate `conf` files for verifying each of them against it.

```
certoraRun ./certora/conf/child/BaseChild.conf
certoraRun ./certora/conf/parent/BaseParent.conf
```

The `Parent` and `Child` specs verify behaviors particular to their respective peers.

```
certoraRun ./certora/conf/parent/Parent.conf
certoraRun ./certora/conf/child/Child.conf
```

The `Yield` spec verifies internal properties of the abstract `YieldPeer` contract such as depositing to and withdrawing from strategies, as well as CCIP tx handling.

```
certoraRun ./certora/conf/Yield.conf
```

The `ParentCLF` spec verifies logic related to Chainlink Functions and Automation.

```
certoraRun ./certora/conf/parent/ParentCLF.conf --nondet_difficult_funcs
```

The `--nondet_difficult_funcs` flag is required for `ParentCLF` to [automatically summarize functions](https://docs.certora.com/en/latest/docs/prover/cli/options.html#nondet-difficult-funcs) in the `FunctionsRequest` library because otherwise the Certora Prover will timeout. The Certora Prover explores all possible paths and the `FunctionsRequest::encodeCBOR` includes an extremely high path count, making it difficult to verify.
