# Preemptive Provable Assertions

## Overview

I'd like to describe a mechanism to extend the flexibility of rollups. The core insight was introduced in Nethermind's [Same Slot L1->L2 Message Passing](https://ethresear.ch/t/same-slot-l1-l2-message-passing/21186) design and I would generalise it to the statement:

> L2 users (and contracts) can rely on arbitrary assertions about future state, provided their transactions are conditioned on those assertions eventually being proven.

This article will unpack that statement and provide some example use cases. We will cover:

- Background information about rollup communication, focussing on timing.
- Anchor blocks for reading L1 state.
- A structure to generalise the same-slot message passing mechanism.
- A mechanism for realtime L1 reads.
- A mechanism for interdependent L2 transactions.
- A mechanism for cross-rollup assertions.

## Background

Every 12 seconds, Ethereum selects an L1 proposer that can aggregate new L1 transactions into a block and add it to the chain. 

<p align="center"><img src="./provable_assertion_images.0.png"/></p>

L2 transactions are derived from data published in an L1 transaction. Typically, they are aggregated into L2 blocks with a shorter block time, so there are several L2 blocks per L1 block.

<p align="center"><img src="./provable_assertion_images.1.png"/></p>

Now consider the question: does any particular L2 transaction (green in this example) execute before the previous L1 transaction (orange)?
<p align="center"><img src="./provable_assertion_images.2.png"/></p>

In the context of composability, we are considering how the content of one transaction can be influenced by another, rather than metadata like block timestamps. Even so, this is ambiguous because it depends on the interpretation.

If you consider the final transcript that reaches consensus, only the L1 ordering (after accounting for any re-orgs) is meaningful. The orange transaction clearly comes first because it can affect how the transactions in the L2 publication are processed, whereas the reverse is not true. This interpretation is also consistent with my previous claim that L2 transactions are derived from the L1 publication, which suggests they don't exist until they are recorded on L1.

On the other hand L2 blocks are actually constructed before the corresponding L1 block and may even be preconfirmed, which means the sequencer cannot freely modify them without paying some penalty. L1 transactions might be constructed in response to L2 preconfirmations, even if they are positioned first in the final transcript. This is particularly true whenever an L2 publication spans multiple L1 slots, which is the typical behaviour.

<p align="center"><img src="./provable_assertion_images.3.png"/></p>

In this article we are focussed on potential functionality that can be offered by the monopoly sequencer for one particular slot (or one that has made the appropriate agreements), so they can credibly offer execution preconfirmations. Therefore, we will default to the second interpretation where L2 blocks are continuously created and finalized (in the sense that the sequencer won't change them) before they are posted to L1. Even if we 

## Anchor blocks

We need a mechanism to send messages from L1 to L2, so that L2 users and contracts can react to L1 activity. I will describe Taiko's standard architecture, although the concepts are broadly applicable across rollups.

The L2 sequencer is required to start each block with an _anchor transaction_, and pass in a recent L1 block number and state root as arguments. Any user can then prove that a particular storage value is consistent with the latest state root, and the rest of the chain can proceed with this knowledge.

For example, consider a snapshot spanning a cross-chain token deposit and a few subsequent L2 blocks:

- an L1 bridge contract receives the tokens and records this fact in L1 storage (the dark green transaction in the below diagram).
- the L2 sequencer passes the latest L1 state root (pink) to the anchor transaction at the start of an L2 block.
- the token recipient (or anyone else) provides a Merkle proof to an L2 bridge contract demonstrating that the deposit was saved under the relevant storage root within the L1 state root. This convinces the L2 bridge that the deposit occured on L1, so it releases or mints the L2 tokens (light green).
- those tokens are now immediately available to interact with the rest of the L2 ecosystem in future transactions and blocks.

<p align="center"><img src="./provable_assertion_images.4.png"/></p>

Note that at this point the sequencer has directly asserted the L1 state without justification. Although it is public information (in the sense that anyone can retrieve the value from an L1 node), this cannot be validated from inside the L2 EVM so L2 contracts must simply trust that it was correct. A sequencer that passes an invalid state root could fabricate a plausible alternate history that would be self-consistent from within the L2 EVM. This is eventually resolved when the bundle is published to the L1 inbox contract, which queries the relevant block hash so it can be compared to the injected state root.

<p align="center"><img src="./provable_assertion_images.5.png"/></p>

### Security architecture

Let's review the security architecture implied by this mechanism. Constraints on L2 sequencers can be categorised as either:
- rules of the rollup, enforced by the L2 nodes and validity proofs.
- other commitments (such as preconfirmations), enforced by economic stake and reputation.

The anchor block requirement (and other assertions described in this article) fall into the first category. This means that all relevant information needs to be available on L1 and when using ZK or TEE proofs, it also needs to be verifiable from within the L1 EVM. This is achieved by some combination of:
- performing relevant validations in the L1 Inbox contract at publication time.
- saving a hash of the available information at publication time, so it can be use to constrain the inputs to an off-chain proof.

In this case, the complete procedure is:
- the sequencer reads the latest L1 state and block number from their node.
- the sequencer passes these values to the anchor transactions, which saves them in the L2 state.
    - in the Taiko case there is an anchor transaction per L2 block but only ones that update the latest L1 state are relevant for this article.
- the sequencer continues to build L2 blocks, and possibly preconfirms them.
- eventually the sequencer submits the whole bundle to the L1 Inbox contract.
- the Inbox contract calls `blockhash(anchorBlockNumber)` and saves (a hash of) it along with the publication.
- the rollup's state transition function, implemented by the rollup nodes, validates the consistency of the entire bundle, which includes confirming (among many other things) that:
    - the anchor transaction is called exactly once at the start of every block.
    - the block number and state root arguments are consistent with the block hash queried by the L1 inbox.

In this way, a sequencer that asserts the wrong state root would invalidate the whole publication, just like they would if they violated any other state-transition rules, like exceeding the block gas limit. Any L2 transaction that reacted to the invalid root (by minting tokens that did not have a matching L1 deposit, for instance) would be contained inside an invalid publication, so it would not be included in the final transaction history.

As we have seen, the sequencer's claim when constructing the anchor transaction is not strictly "this is the state root of the latest L1 block" but rather "this state root is consistent with the block hash that will be retrieved in the publication block". This describes a general pattern that we can use whenever:

- the sequencer knows something that they want to assert inside the L2 EVM, so that L2 users and contracts can build on it.
- the information needed to prove the claim will eventually be verifiable in the L1 EVM at publication time.
- the rollup's state transition function requires the claim to be proven for the publication to be valid.


## Same Slot Message Passing

This idea was [introduced by Nethermind](https://ethresear.ch/t/same-slot-l1-l2-message-passing/21186) and as noted in that post, it can be combined with their fast-withdrawal mechanism to perform a same-slot round-trip operation. Here I will just focus on the assert-and-prove structure of the L1-to-L2 message.

As noted, the anchor block mechanism requires the Inbox contract to query the block hash of the relevant L1 block, which implies it cannot be used to react to transactions included in the current L1 block. However, an L2 sequencer that can predict a particular L1 transaction will be included in the publication block (either because this is a based rollup or the sequencer has seen an L1 preconfirmation) can assert that claim immediately in the L2.

<p align="center"><img src="./provable_assertion_images.6.png"/></p>