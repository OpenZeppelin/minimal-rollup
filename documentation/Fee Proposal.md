# Fee Proposal

## Overview

- I have an intuition that some of the L2 fee-pricing challenges are downstream of reusing and modifying the L1 pricing model, which may not be aligned with the economics of L2s.
- Following similar intuitions to the [generic assertions](https://github.com/OpenZeppelin/minimal-rollup/pull/123) idea, I think rollups should just enforce security-relevant properties and then provide a framework for developers to build whatever they want. We can provide example implementations but they should not be part of the core protocol.
- In this case, I suspect we can simplify the protocol fee requirements. It doesn't remove the complexity of figuring out how much to charge, but it pushes it up to the smart contract layer, which should improve flexibility and allow participants to respond to market conditions. 
- I have low confidence in this claim - it's quite possible I'm missing something crucial. Part of the point of this document is to think through the idea. Feedback is very much encouraged.

## Background

- As I understand it, the whole L1 gas metering mechanism is supposed to limit third-party costs on staking validators:
   - the block gas limit ensures consumer-grade validator devices can keep up with the chain
   - the gas price ensures users pay the "costs to the network" for replicating the operation across thousands of validators. It's not perfect because the validators do not receive the payment, but they are compensated by the staking/reward mechanism.
- In the L2 case, there are no relevant _staking_ validators. We don't actually care how many people run L2 nodes, so there are no actual "costs to the network".
- The gas target is not about security, but it is a useful mechanism to smooth out the price volatility produced by sudden changes in demand. We should aim to preserve this property.

## Idea

### Transaction Costs

- The basic idea is to remove the in-protocol fee mechanism (and the implicit gas target), by setting the base fee to zero.
- I think we still want a gas limit so that anyone running a node can reasonably say "if my node has X resources, I will be able to keep up with the chain", but it doesn't need to target consumer devices. I suspect the L1 costs and proving costs will constrain the practical limit, but data-light compute-heavy transactions (or actual attacks like running an infinite loop) may hit the enforced limit.
- In this way, the protocol is no longer opinionated about how much to charge for each opcode (except in the sense that some opcodes will consume more of the gas target).
- Users can incentivize the proposer to include their transaction using any offchain or L2-mechanism they want. The proposer could reproduce the current behaviour by measuring the gas used and charging accordingly, but they could also use arbitrary tokens, or change the metering mechanism, or offer discounts for compressible calldata. From the rollup's point of view, if the proposer is willing to pay the L1 costs, then how they charge users is up to them.
- If we want to retain the EIP1559-style targetting mechanism to smooth out price volatility, that could be achieved by forcing proposers to pay (or burn) L2 ETH when they exceed the target and adjust the target whenever this happens. The difference is that the penalty is applied directly to the proposer, not the individual transactions.

### Proving costs

- Similarly, proposers must post a liveness bond with each publication. The protocol will guarantee:
    - if the publication is proven in time, the liveness bond is sent to a proposer-specified refund address.
    - otherwise, whoever proves it gets the liveness bond.
    - the liveness bond is large enough to cover the worst-case "prover killer" blocks (but otherwise does not need to be responsive to the details of the publication or proving costs).
    - this almost certainly implies the liveness bond will also cover proving that a publication is invalid (so it becomes an empty block). 
    - in either case, there is always an incentive to prove an expired publication.
- To facilitate enforceable prover/proposer commitments (like an [auction mechanism](https://github.com/OpenZeppelin/minimal-rollup/blob/main/src/protocol/BaseProverManager.sol)), the protocol could:
    - allow an optional special transaction (at the start or end of the publication) that calls `validatePublication` on an arbitrary L2 address chosen by the proposer and passes:
        - the refund address on L1 
        - a hash of the transactions in the publication
        - an arbitrary buffer containing any relevant additional information
    - the state transition function will guarantee (similar to the "consistency hash" mechanism described in the generic assertions post linked above) that these values are set correctly (or the publication defaults to an empty block).
    - note that other than these guarantees, this behaves like a regular transaction that can change L2 state in any way including transferring tokens or ETH. It's still free for the proposer to call it (since the base fee is zero), but it does consume some of the gas limit.
- The L2 address represents a prover, and the `validatePublication` function will ensure the prover is willing to prove that publication. It could be designed (but this is not enforced) so that:
  - it sends the liveness bond minus its chosen fee to the proposer
  - it ensures the L1 refund address belongs to the prover
  - In this way
    - the prover contract can decide how much to charge for the particular publication using whatever rules it wants
    - any proposer can accept the deal by constructing a publication that invokes this prover contract
  - in the happy case
    - the proposer paid the L1 liveness bond, which will be sent to the prover
    - the prover paid a slightly smaller amount to the proposer on L2. The difference is the proving fee.
  - in the unhappy case
    - the proposer still pays the proving fee (in effect)
    - the specified prover pays the rest of the liveness bond as a penalty
    - both amounts are given to the actual prover
- We could avoid actually transferring funds between L1 / L2 (or requiring the proposer to have L1 funds) by using a slightly more complicated refund address that both provides and receives the bond (like a flash loan), and the prover contract on L2 would retrieve the fee rather than refund the bond amount.
- If the `validatePublication` function fails (so the specified prover contract did not actually agree to prove the publication), the actual prover will need to show the publication has empty blocks. The liveness bond (paid by the proposer) should be enough to cover this proof.
- Under this design, delayed publications can be treated like regular publications: the user covers the L1 costs but can specify a prover contract so they only end up paying the proving fee.
