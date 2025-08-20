# Taiko Fee Proposal

## Overview
- I have an intuition that some of the L2 fee-pricing challenges are downstream of reusing and modifying the L1 pricing model, which may not be aligned with the economics of L2s.
- In particular, it seems to me that L1 protocol-enforced-fees are useful to:
    - apply a "negative externality fee" to account for costs to the network. This accounts for the cost of running the consensus mechanism.
    - limit the total resource consumption to a level where other network participants can keep up.
        - technically, the actual resource limits (block gas limit and blob number limit) achieve this function, but the fee makes it possible to have a target that it less than the actual limit, to smooth out volatility.
- In the L2 case:
    - there are no relevant _staking_ validators. We don't actually care how many people run L2 nodes so there are no actual "costs to the network".
    - L2 sequencers have to pay L1 publication costs out of their own account.
    - L2 provers have to pay L1 proving costs out of their own account, and may incur significant offchain proving costs.
    - We want a mechanism to direct funds towards the treasury.
- I believe attempting to combine the relevant fees into an L2 base fee is unnecessarily complicated and distorts the market, which leads to attacks and complications.
- Instead, we should analyse the dynamics of each resource independently.

## Proposal

I will first describe my suggested proposal, and then explain the rationale.


1. L2 gas should only cover L2 execution. There are two options:
    - use the existing EIP1559 mechanism, [corrected](https://github.com/taikoxyz/taiko-mono/issues/19160) to account for variable-length blocks.
    - charge for publications (not transactions):
        - set the base fee to zero
        - use an EIP1559-style mechanism to charge the sequencer for the total gas used in their publication and to maintain a per-second gas target.
        - sequencers can decided for themselves how (or even whether) to charge each user for their gas consumption. In the simplest case they would use the L2 priority fee, but users with no ETH could also pay in other tokens or MEV-rich transactions could be subsidized. The protocol remains completely unopinionated about how sequencers charge users as long as the sequencer pays the protocol.
    - some or all of the protocol fee can be directed to the treasury or burned.
2. The protocol does not compute or enforce any L1 data fee requirements.
    - Sequencers pay the L1 publishing costs to the L1 network.
    - They decide for themselves how to charge users for L1 costs.
    - The inbox should save the number of blobs used, `BLOBBASEFEE` and `BASEFEE` with the publication. This can be used to compute the L1 costs, so a surcharge percentage can be deducted from the sequencer (on L2) and sent to the treasury.
        - this could be handled inside the L2 EVM by injecting those values (in the anchor or end-of-publication transaction) and doing a direct transfer.
        - alternatively, it could be computed as part of the state-transition function.
3. Similar to the existing protocol, proposers must post a liveness bond with each publication.
    - The protocol will guarantee:
        - if the publication is proven in time, the liveness bond is sent to a proposer-specified refund address.
        - otherwise, whoever proves it gets the liveness bond.
    - To facilitate enforceable prover/proposer commitments (like an [auction mechanism](https://github.com/OpenZeppelin/minimal-rollup/blob/main/src/protocol/BaseProverManager.sol)), the protocol could:
        - allow an optional special transaction (at the start or end of the publication) that calls `validatePublication` on an arbitrary L2 address chosen by the proposer and passes:
            - the refund address on L1 
            - a hash of the transactions in the publication
            - an arbitrary buffer containing any relevant additional information
        - the state transition function will guarantee (similar to the "consistency hash" mechanism described in the generic assertions post) that these values are set correctly (or the publication defaults to an empty block).
        - note that other than these guarantees, this behaves like a regular transaction that can change L2 state in any way including transferring tokens or ETH and consumes L2 gas (which may be free for the proposer in the scenario where the base fee is zero).
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
    - We could track the agreed proving costs (as part of the `validatePublication` interface) and apply a surcharge to sequencer, directed to the treasury (just like the L1 publication costs). However, since this value is negotiated between the sequencer and prover, the fee could be bypassed by setting the official proving cost as zero and using some other mechanism to pay the fee.

Note that under this design, the costs for a publication are self-contained, so delayed publications can be treated like regular publications.

## Rationale

### Overall Intuition

- The goal is to reflect the real-world costs as faithfully as possible.
- Any opinionated pricing formulas enforced by the protocol, particularly ones that rely on empirically-derived parameters (like average transaction sizes), can get out of sync with the market conditions.
- Moreover, attempting to charge for the wrong resource (eg. L1 costs being included in the L2 base fee) can let users craft transactions that exploit the discrepancy.

### L2 Gas
- As I understand it (although this should be validated), since there is no security reason to encourage users to run L2 nodes, we do not need to charge for "costs to the L2 network". This means the L2 gas fee can be set to zero.
- The sequencer may still want to charge for the offchain processing costs, but this can be incorporated in the priority fee. When combined with the other recommendations, it also means that users and sequencers just need to negotiate a single priority fee to account for all the resources (L2 gas, publication costs and proving costs) associated with the transaction.
- However, we probably do want to include an overall gas limit to ensure that other users can keep up with the chain. I suspect it can be large enough that it is never reached in practice (because the publication and proving cost limits will likely be reached first), but it is still necessary to prevent malicious compute-only transactions (like running an infinite loop).
- Once we've decided to include a limit, I think it also makes sense to have a smaller target, so that unexpected volatility does not create immediate scarcity (and correspondingly very high prices). The EIP1559 mechanism seems like a good way to regulate this.
- However, applying the mechanism to the sequencer (instead of the transactions) has some benefits:
    - it is simpler. We only need to do one update calculation per publication (rather than for every block)
    - We can charge the sequencer at the new rate after accounting for any excess they personally introduced (rather than allowing their publication to increase the costs for the next sequencer)
    - users and sequencers have more flexibility around when and how payments are made.

### Publication Costs
- Since sequencers must pay the publication costs, it seems natural for users to compensate them directly.
- Moreover, sequencers are incentivised to optimise the publication costs, and can pass on those optimisations to the user (for example, they can offer discounts for transactions that compress well with other transactions in the publication).
- When discussing this idea, one concern was that if the publication fee was not incorporated into the base fee, it would not be subject to the EIP1559 mechanism to smooth volatility. I suspect that's incorrect, because the fee should be the sequencer's best estimate at what the L1 publication costs will be, which are already governed by the L1 fee-smoothing mechanism.
- With this mechanism, Taiko does not have to model the L1 changes, but can still direct a fraction of the actual (not estimated) publication costs to the treasury.
    - this doesn't remove the need for sequencers to be able to estimate L1 costs when deciding whether to preconfirm a transaction. However, they can respond to the market conditions in realtime with whatever level of sophistication they have.
    - If standardisation is preferred, Taiko could still create a suggested fee formula that sequencers can use.



### Proving Costs
- Following the same intuitions, if sequencers compensate provers at whatever rate they agree, then sequencers and users are incentivised to optimise the proving costs.
- For example, sequencers can offer discounts for transactions that are easy to prove.
- This also lets Taiko be maximally flexible about the best way to estimate proving costs. Anyone is free to:
    - use a "zk-opcode" method
    - use L2 gas as a proxy for proving costs
    - invent a new method specialised for their proving hardware.

## Wallet compatibility

There are two challenges that I think will need to be addressed, and may depend on the cooperation of wallet developers:

- Fee discovery
    - Sequencers will need a way to signal to wallets how much they would charge for a given transaction
    - I'm not sure how this works in practice, and whether wallets can change which endpoint they query based on who the next sequencer is, or if sequencers can register their fee calculation with some shared provider.
- Using total fees
    - As I've described the mechanism, the transactions will pay some base fee (possibly zero) associated with the L2 gas execution, and should also specify a priority fee to account for the other charges
    - However, current transaction types require them to specify a _priority fee rate_ (not absolute fee) against L2 gas.
    - As noted, I don't think they should charge per unit of L2 gas execution, so they will need to compute the total fee and then divide it by the actual gas consumed.
    - Unfortunately, users do not necessarily know exactly how much gas will be consumed when constructing the transaction because that might depend on if any other transactions change the state before this transaction is sequenced.
    - Ideally, this would be solved with a new transaction type, allowing users to specify the total priority fee.
    - Until then, sequencers will need to simulate the transaction to determine the actual gas consumed, and only then can they figure out whether the priority fee will be sufficient.
    - They could also use a wrapper smart contract that first executes the transaction and then consumes the remaining gas so that the transaction gas limit would be equivalent to the actual gas consumed, but this seems pretty hacky.

## Alternatives

- To address the question of wallet compatibility, I should get familiar with how wallets choose fees and display them to users. At this point I do not have enough background to understand claims about whether it is or is not possible.
- I will be offline for a few days, but in the mean time, I think it might be worthwhile to consider alternatives, to provoke a discussion and better pinpoint exactly what the constraints are.

### Independent L2 charges

- If we cannot use priority fees (or it is too difficult to use the priority fee rate), my preference is to use an external L2 mechanism to charge the fee.
- For example:
    - sequencers could require all transactions to go to a wrapper contract that extracts fees (potentially in tokens) as part of the user operation
    - sequencers could require users to create independent transactions that pay the fees directly
- This is a minor preference because the annoyance of having an external mechanism may be worse than poorly specified fees.
- If we do go down this path, we should create a standard default mechanism (eg. a standard wrapper contract) to minimize inconsistencies.

### Sequencer chosen base rate

- If we do decide to use the L2 base fee for all charges, it's not clear to me why Taiko needs to be opinionated about the amount.
- Can we just let sequencers pick an arbitrary base fee for their blocks, disconnected from whatever else is happening in the protocol?
- My rationale is:
    - as noted, we do not need to ensure they cover "costs to the network"
    - this is another way of letting users and sequencers negotiate a market price, based on the realtime expected costs
- Potential counterarguments (and my response):
    - this could lead to issues where compute-heavy transactions subsidize the data-heavy transactions
        - I think that's a consequence of charging the same base fee for all transactions, and charging for each computational step. As far as I can tell, it's not worsened by choosing any specific number.
    - this may allow wide price swings between publications if some sequencer chooses a ridiculously high gas fee amount.
        - I think that risk already exists, because sequencers can demand high priority fees or refuse to sequence transactions that spend too little gas. Since sequencers have monopoly power, any scheme we come up with is going to be vulnerable to sequencers making ridiculous demands. The solution has to be some version of users setting reasonable maximum fee limits
        - On the other hand, the ability to allow massive price swings may actually just be sequencers responding to real-world market conditions.
        - It also lets users and sequencers be more creative about how to arrive at the correct charge given the base-fee constraint. For example, the sequencer could include all data-heavy transactions in a block with a high base fee (to indirectly charge for the L1 blobs), and then go back to regular block charges for regular L2 transactions.
- Any feedback on if I'm missing something would be appreciated.


## Resolution

- As I understand it, this recommendation is not possible for Taiko because existing wallets do not have standard RPCs for fetching priority fees.
- Moreover, we cannot use the "Sequencer chosen base rate" alternative, because (most) wallets compute the base fee from internal node logic, so there is no place for the current sequencer to inject their preference on a per-transaction basis.
- We cannot manipulate the L2 block-producing mechanism to change the base fee arbitrarily on a per-block basis (which would allow seqeuncers to group data-heavy transactions into the same block) because the preconfirmation mechanism now enforces regular block lengths (of 2 seconds).
- Overall, this implies that at least for now, any solutions must involve
   - setting the base fee for all transactions in a particular 2-second window
   - be computable from a predetermined formula
   - be charged against L2 computational steps
- As noted already, this means the fee will not correctly track the cost of the resources it consumes.
- Ideally, we should push for more flexible fee-choosing mechanisms, particularly for the priority fee. My preference is:
    - accounts should be able to specify how they would like to select fees.
        - note that this doesn't change anything about what fees are enforced by the protocol. L1 must still charge gas fees as a proxy for network costs, but L2s could set the base fee to zero.
    - they should be able to specify a total priority fee as well as the priority fee rate.
    - wallets will choose the fees they present to the user (before signing) as follows:
        - if the account has specified an actual formula they want to use, use that.
        - if the account has specified an RPC to call, use that.
        - if the account has not specified a fee-choosing mechanism, use whatever mechanism they currently use.
- Until then, there are two kinds of risks that I see:
    - the best case scenario is that the base fee correctly tracks the overall cost for average transactions. However, sequencers can only signal desired changes for future publications, which distorts the incentive to get it right, particularly for a diverse set of sequencers.
    - transactions with higher than average data-to-L2-compute ratios will be underpriced.
        - such transactions will either be subsidized by the sequencer, or will not be included at all.
        - moreover, sequencers may have to process these transactions (since the actual gas consumed will be unknown until it is executed locally) before deciding to discard them.
    - the same problem exists for transactions with higher than average proving-cost-to-L2-compute ratios.
    - transactions with lower than average data-to-L2-compute or proving-cost-to-L2-compute ratios will be overpriced.
- Note that this doesn't change the treasury fee analysis. I still believe that Taiko can direct a fraction of the measured L1 costs to the treasury, instead of (or in addition to) the base fee fraction.