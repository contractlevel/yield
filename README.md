# Contract Level Yield (CLY)

This project is being built for the Chainlink Chromion Hackathon.

## DefiLlama Proxy API

```
cd functions/defillama-proxy
npm i
```

The `function.zip` file located in `functions/defillama-proxy` has been uploaded to AWS Lambda and deployed. This was needed because we are using the DefiLlama API to fetch data about APYs, but the payload response was too large for Chainlink Functions, so we filter on the server side via our proxy API.

## Certora

```
certoraRun ./certora/conf/Yield.conf
certoraRun ./certora/conf/ParentCLF.conf --nondet_difficult_funcs
```

The `--nondet_difficult_funcs` flag is required for `ParentCLF` to automatically summarize functions in the `FunctionsRequest` library because otherwise the Certora Prover will timeout.
