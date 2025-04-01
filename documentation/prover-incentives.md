# Efficient prover incentives

This document describes an ahead of time auction mechanism that allows provers to bid for the right to prove multiple publications for a rollup. The mechanism is guided with the following principles in mind:

- Decouple the roles of proposing and proving.
- Assigning proving rights to one prover at a time to avoid redundant efforts, which results in cheaper costs for users.
- Providing proposers with predictable costs when submitting publications.
- Simple design and minimal L1 gas costs.

> [!NOTE]
> An initial implementation of this design can be found in the [ProverManager contract](../src/protocol/taiko_alethia/ProverManager.sol).

*The specifics of the mechanism are still being discussed, and some of the details might change as we do more research on the incentives.*

## The problem

Verifying proofs on Ethereum L1 is a [gas-intensive operation](https://docs.alignedlayer.com/#why-are-we-building-aligned). For example, Groth16 proofs, among the cheapest, cost around 250k gas, while STARKS can exceed 1M gas. As a result, most zk-rollups call their inbox contract's verification function only sporadically.

For based validity rollups, achieving a similar property raises the question: Who should verify batches submitted to L1, and how can proposers be incentivized to submit valid batches if proofs aren’t generated immediately? A common solution is to require proposers to deposit a bond when submitting a batch. If they fail to provide a validity proof within a set time window, they lose their stake, and proving becomes permissionless. This approach is currently used by Taiko.

In Taiko, after the Pacaya fork, proving multiple non-consecutive batches will become possible (open to anyone). However, the rewards go to the proposer if a batch is within its proving window (currently 60 minutes). While this adds flexibility, the incentives remain largely the same: proposers are motivated to prove only their batches(by running a prover themselves or by paying a prover), which doesn’t optimize proving costs.
If proposers are sophisticated enough, an off-chain market might develop where multiple proposers pay the same prover to generate proofs for their batches. The prover can then aggregate these proofs for greater efficiency. However, this scenario is still uncertain to happen and could lead to centralization, as provers seek deals with as many proposers as possible to maximize consecutive batches. Even if this market develops, there are still some concerns:

- If different batches have different provers, none may be incentivized to prove the entire set.
- The rollup has to store multiple checkpoints in the Inbox contract(or some other contract), because proving may happen out of order. This means more storage costs.
- Payments happen off-chain, and the protocol has no visibility or control over incentives.
- It may lead to proposer centralization, since it rewards proposers for being more sophisticated and making this off-chain agreements.

## Proposed design

We propose a design where an auction happens on-chain, and the protocol has visibility and control over the incentives.

Anyone can register as a designated prover by specifying their fee **per publication**. The prover offering the lowest fee gains exclusive rights to prove publications until another prover undercuts them with a lower fee. This ensures proposers know the exact cost of proving their publications upfront, eliminating the need for additional capital and improving capital efficiency and participation.
To prevent bidding wars (i.e., new participants undercutting by just one wei) that can cause unnecesary gas spikes, new provers must offer a fee that is **at least a defined percentage lower** than the current lowest fee.

*This system functions effectively as a reverse English auction conducted ahead of time.*

![Prover auction](./images/prover-market.png)

While publications vary in the proving cycles they require, provers should account for this variability. Since L1 lacks a way to calculate these differences, provers should base their bids on an average case.

To deter malicious or inactive provers, they must stake funds when registering by putting a `livenessBond` as collateral. This stake is slashed if they fail to fulfill their duties and can be used to reward the next prover (who may charge a higher fee, even though proposers have already paid the previous amount). We introduce a `livenessWindow`, which is the maximum time a prover can take to prove a publication. If the prover doesn't prove the publication within this time, they can be evicted by anyone for a portion of their stake(more details in the [Fallback Mechanism](#fallback-mechanism) section).

*The required stake amount is yet to be defined but should be sufficient to incentivize other provers to step in if the current prover becomes inactive.*

### Transition Periods

The ideal system grants a prover exclusive rights for an extended period, enabling them to aggregate proofs for multiple publications and submit them in a single L1 transaction, reducing on-chain costs.

Frequent changes in provers should be avoided, as they lead to inefficiencies and unpredictability. Fortunately, this is naturally incentivized, as the per-publication fee charged by provers should converge to the actual proving cost. However, transition periods are introduced to manage scenarios where a prover is outbid or chooses to exit.

- `successionDelay`: The time between a prover being outbid and the new prover starting their period. During this window, other provers (or the existing one) can offer a lower fee.
- `exitDelay`: The time between a prover’s request to exit (or ejection due to inactivity) and the new prover starting their period.

**We refer to the proving window (the time and publications assigned to a specific prover) as a `period`.**
Provers are rewarded only for publications proven within their period and regain their stake once the period concludes (i.e., all assigned publications are proven).

### Fallback Mechanism

Whenever a registered prover fails to deliver a proof after a certain time threshold(`livenessWindow`), anyone can call the `evictProver` function to claim a portion of the inactive prover’s stake and mark them as inactive. This flags the current prover for slashing and initiates an auction during the `exitDelay` window (described in the previous section) to select a new prover.

You might wonder how we handle unproven publications from the offending prover. Currently, we **make proving these publications permissionless**. The prover who proves them is rewarded with a portion of the offender’s stake, while the remainder is burned (or sent to the treasury). Fees for unproven publications go to the new prover, while fees for publications already proven by the offender still go to them. Another option is to assign the rights to prove these publications to the prover who wins the auction for the next period, but then we need to handle the fallback mechanism for them as well. For now, we opted for the simpler approach.

### Dealing with forced inclusions

**How to deal with forced inclussions is still being discussed. This section describes our current thinking on the subject.**

In our current design, forced transactions are posted as blobs but are routed to a separate queue. They are picked up when the next proposer calls `publish` on the Inbox to submit their publication. For now, we’ve decided that forced transactions will be posted as a **new publication** within the same function call. This approach is cleaner, easier to price, and avoids the risk of a single combined publication becoming too large to prove.

However, this raises a question: **How should we price these delayed publications?** Should the forced includer pay, or should they free-ride on the next proposer?

While the exact proving cost at the time of inclusion may be uncertain (since the current prover’s term might have ended), allowing free-riding creates negative incentives. Actors could batch as many transactions as possible into delayed publications, securing a lower execution price by waiting for inclusion. This penalizes the prover (who must prove a large publication without adequate compensation) or the proposer (if they are forced to cover the cost).

The proposed solution is to require the delayed proposer to pay a proving fee, **set higher than the regular fee** for the following reasons:

1. **Size:** Delayed publications can accumulate transactions over an arbitrarily long time, making them potentially much larger than regular publications (limited only by data availability).
2. **Uncertainty:** Proving costs may increase by the time the publication is included.
3. **Incentives:** We want to discourage the formation of a market where actors batch transactions for delayed inclusion simply because it’s cheaper. Unless censored, users should follow the regular flow.

> [!NOTE]
> This has not been implemented yet, and pricing delayed publications differently has the practical downside that we need to keep track of inidividual publications fees on the ProverManager contract, which increases storage costs.

## Alternatives

Is designing an on-chain incentve mechanism the only way to solve this problem? No, but we believe it is the most practical today, and can still be combined with other approaches if/when they become available. Here are some of the alternatives we have explored:

- Off-chain market: Some of the dynamics of the proposed design can be achieved off-chain, but the incentives remain outside of the protocol's control and has some negative externalities described in the [The problem](#the-problem) section.

- [Aggregation layers](https://ethereum-magicians.org/t/a-simple-l2-security-and-finalization-roadmap/23309#p-56644-h-3-work-on-aggregation-layers-3) can help solve this problem by amortizing the costs among multiple rollups, but we still don't have common standards and a layer that does not introduce new security tradeoffs. Eventually, we want rollups to post proofs to L1 every slot, but we are still away from that. Even when using aggreagaton across multiple rollups, it will be useful to have a mechanism to allow a single prover to generate proofs for multiple consecutive batches.
