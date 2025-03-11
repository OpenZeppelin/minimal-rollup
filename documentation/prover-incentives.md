# Efficient prover incentives

This document describes an ahead of time auction mechanism that allows provers to bid for the right to prove multiple publications for a rollup. The mechanism is guided with the following principles in mind:

- Decouple the roles of proposing and proving.
- Assigning proving rights to one prover at a time to avoid redundant efforts, which results in cheaper costs.
- Providing proposers with predictable costs when submitting publications.
- Simple design and minimal L1 gas costs.

*The specifics of the mechanism are still being discussed, and some of the details might change as we do more research on the incentives.*

## The problem

Verifying proofs on Ethereum L1 is a [gas-intensive operation](https://docs.alignedlayer.com/#why-are-we-building-aligned). For example, Groth16 proofs, among the cheapest, cost around 250k gas, while STARKS can exceed 1M gas. As a result, most zk-rollups call their inbox contract's verification function only sporadically.

For based validity rollups, achieving a similar property raises the question: Who should verify batches submitted to L1, and how can proposers be incentivized to submit valid batches if proofs aren’t generated immediately? A common solution is to require proposers to deposit a bond when submitting a batch. If they fail to provide a validity proof within a set time window, they lose their stake, and proving becomes permissionless. This approach is currently used by [Taiko].

After the Pacaya fork, proving multiple non-consecutive batches became possible (open to anyone). However, the rewards go to the proposer if a batch is within its proving window (currently 60 minutes). While this adds flexibility, the incentives remain largely the same: proposers are motivated to prove their batches or hire a prover, which doesn’t optimize proving costs.
If proposers are sophisticated, an off-chain market might emerge where multiple proposers pay the same prover to generate proofs for their batches. The prover could then aggregate these proofs for greater efficiency. However, this scenario is uncertain and could lead to centralization, as provers would seek deals with as many proposers as possible to maximize consecutive batch proofs and off-chain payments. If different batches have different provers, none may be incentivized to prove the entire set.

- This also has the downside that you have to store multiple checkpoints in the Inbox contract, because proving may happen out of order.

## Proposed design

Anyone can register as a designated prover by specifying their fee **per publication**. The prover offering the lowest fee gains exclusive rights to prove publications until another prover undercuts them with a lower fee. This ensures proposers know the exact cost of proving their publications upfront, eliminating the need for additional capital and improving capital efficiency.
To prevent bidding wars (i.e., new participants undercutting by just one wei) that can cause unnecesary gas spikes, new provers must offer a fee that is **at least a defined percentage lower** than the current lowest fee.

*This system functions as a reverse English auction conducted ahead of time.*

![Prover auction](./images/prover-market.png)

While publications vary in the proving cycles they require, provers should account for this variability. Since L1 lacks a way to calculate these differences, provers should base their bids on an average case.

To deter malicious or inactive provers, they must stake funds when registering. This stake is slashed if they fail to fulfill their duties and can be used to reward the next prover (who may charge a higher fee, even though proposers have already paid the previous amount).

*The required stake amount is yet to be defined but should be sufficient to incentivize other provers to step in if the current prover becomes inactive.*

### Transition Periods

The ideal system is one where a prover has the right for an extended period of time. This allows them to aggregate proofs for multiple publications and post them in a single L1 transaction, reducing the on-chain costs.  
We want to avoid scenarios where provers are constantly changing, since this would result in less efficient proving costs and a lot of unpredictablity for provers. The good news is that this should happen naturally, as the price per publication they charge should converge to the cost of proving. But we still introduce a transition period when a prover is outbid or wants to exit.

- `succesionDelay` is the time window between when the prover is outbid and when the new prover can start their period. During this time other interested provers or the existing one can come in and offer an even lower price.
- `exitDelay` is the time window between when the prover wants to exit and when the new prover can start their period. It is also the time window between when an inactive prover is ejected and when the new prover can start.

**We call the proving window(the time and the publications that are assigned to a specific prover) a `period`.**
Provers are only rewarded for the publications they proved within their period and returned their stake after their period is closed(all the publications have been proven).

### Fallback Mechanism

What happens if the prover does not deliver on their promise and does not prove anything after a certain period of time? We now need a new prover to step in. Anyone can calll `eject` to receive a portion of the prover's stake and mark them as inactive. This marks the current prover as ready to be slashed(we will discuss the details in a later section) and allows a new prover to step in(an auction occurs during the `exitDelay` window described in the section above).

*In the case no independent prover is willing to step in for whatever reason, or the ones that are collude and decide to charge an insane amount, the system can still maintain liveness assuming the rollup operator is willing to run a prover and is assumed not to want to extract excessive value from their users.*

At this point you may wonder what we do with the unproven publications from the offender prover? The way we deal with this currently is by **making proving those publications permisionless**, and rewarding the prover that proves them with a portion of the offender's stake while burning the rest(how much is burned or if it is actually sent to the treasury instead of burned is yet to be defined). The fees for the unproven publications are paid to the new prover, and the fees for the ones that were already proven by the offender are still paid to them.

### Dealing with forced inclusions

**How to deal with forced inclussions is still being discussed. This section describes our current thinking on the subject.**

In our current design, forced transactions are still posted as blobs, but go to a separate queue and are picked when the next proposer calls publish on the Inbox to post their next publication. For now we have decided that they will be posted as a new publication inside the same function call(a new publication is cleaner, easier to price and avoids the risk of a single combined publication being too big to prove).

But we now have a problem to solve: how do we price these delayed publications? Should we charge the forced includer or allow them to free ride the next proposer?
While we don’t always know exactly the proving cost when their transactions will be included(since the current prover turn might be over by the time this publication is included), allowing a free ride creates negative incentives, where actors are incentivized to batch as many transactions as they can and post them in a delayed publication, giving them a lower execution price as long as they are willing to wait that time for their inclusion. This penalizes the prover, who now has to prove a very big publication that he is not compensated for(or the proposer if we make him pay for the publication).

The proposed solution is to ask the delayed proposer to also pay a proving fee, **but this should be higher than the regular proving fee** because of:

1. Their publication are potentially much larger than the regular proposer publication(since they can accumulate transactions for an arbitrarily large amount of time and are limited by DA only)
2. Proving cost is not always known, so it might actually go up by the time it is time to prove their publication
3. We want to disincentivize the formation of a market where an actor batches multiples transactions from people and include that with a delay just because it is cheaper. Unless you are getting censored you should go trough the regular flow.
