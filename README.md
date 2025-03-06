# Minimal Based Rollup Protocol

This repository contains the [smart contracts](src/) and [documentation](documentation/) for a based rollup stack that Taiko Alethia and other rollups will use. This stack will support preconfirmations from day one and is designed to be **minimal - this means easy to understand, audit and extend**.

## Goals

1. **Minimal L1 footprint - cheaper costs for proposing, proving and sending messages**
    - If it can be kept offchain, it should be kept offchain
    - As a general principle we avoid writing to a new slot, we overwrite an existing storage slot if possible
    - Our main priority is to make block proposing cheap, since that occurs more frequently than proving under the new design and also incentivizes more proposers to participate
2. **Maximally simple core protocol, but easy to extend**
    - The core layers of the protocol are as simple as possible, with minimal functionality(e.g. `PublicationFeed`, `CheckPointTracker`, `SignalService`) and the layers above still provide useful functionality that most rollups need, but can be replaced by each rollup(e.g. `ERC20Bridge`, `ProverMarket`, individual inbox contracts)
3. **More efficient prover incentives**
    - The biggest cost for provers today is on-chain verification and the roles for proposers and provers are mixed. This, together with proof aggregation, is a big reason to aggregate proofs for multiple publications by creating incentives for provers to do so. More details [here](documentation/prover-incentives.md).
4. **If a new rollup that uses the stack is deployed, it should be very easy to do asynchronous communication**
5. **Deploy your rollup with one click, just minimal changes**
    - We still need to flush out this more, but the main goal is: you register your chain, deploy a set of smart contracts and you quickly have L1 proposers sequencing your chain and provers that are participating in the proving market generating proofs for your rollup.
6. **Accurate and predictable L2 base fees**
    - L1 base fees and blob base fees are brought in and are used in conjunction with L2 congestion to calculate an L2 base fee that better reflects the real costs. Since we have the prover fees we can also use that as an input.

## Non Goals

1. Synchronous composability: We are realistic about the fact that real time proving will still take some time - so at least for now, the stack is not designed to be synchronous composable, but it is designed to embrace it in the future.
2. AltDA support: The stack is designed to work only with Ethereum as DA, more especifically blobs. It shouldn't be too hard to extend it to other DA(s), but it is not provided out of the box.
