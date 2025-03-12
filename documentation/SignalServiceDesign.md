## Signal

The Taiko stack refers to cross chain message passing as 'signalling'. The process of signalling consists of writing to a storage location so that it can later be proven on a destination chain using a storage proof.

A signal is stored at a pseudorandom storage slot derived via [erc7201](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/ca7a4e39de0860bbaadf95824207886e6de9fa64/contracts/utils/SlotDerivation.sol#L4). This signal consists of the `msg.sender`, `chainId` and `value`.

## Normal ‘slow’ Message Passing

In our current protocol, signalling is performed by storing a message at a specific storage slot, then, once the L1 state root is accessible on the L2, executing a storage proof to verify that value exists. This proof can then trigger certain logic, such as minting tokens.

Currently each application is responsible for their own signalling (i.e. there is no central storage of all signals). This means any potential relaying must be done on an app by app basis. We only provide a standard signalling library to store and verify signals on chain.

This approach works well, but has some latency since the latest L1 state root in the case of Taiko is only accessible when the L2 proposer submits a new publication to the L1 and includes a new anchor tx to the L2.

## Same Slot L1 → L2 Message Passing

The signal service (SS) is used for cases where the message is to be sent within the same slot. This [design](https://ethresear.ch/t/same-slot-l1-l2-message-passing/21186) is the one proposed by Nethermind. The basic idea is as follows:

1. The proposer listens to any signals being stored on the L1 SS
2. The proposer (during his allocated slot) can selectively inject L1 → L2 signals when proposing a batch in the `publish` function.
3. The inbox contract will verify that the Signals exist in the SS’s storage.
4. The proposer (owned by the rollup) will call `receiveSignal` on the L2 SS through the anchor transaction executed at the start of L2 blocks. This will fill a mapping of `_receivedSignals` to true (signal —> true)
5. Any application that requires same slot signalling will just verify the signal is found in the `_receivedSignals` mapping i.e. they don’t need to provide a storage proof

An example diagram is provided in the ETH bridge section.

---

## Bridging

Bridges are one of the main use cases of signalling.

### ETH Bridge

The L2 ETH bridge is presumed to have unlimited ETH, functioning as the canonical bridge for transferring assets to Taiko rollups. The ETH bridge makes use of both 'fast' and 'slow' signalling pathways as described above, allowing users to choose between immediate transfers with potential higher costs and slower transfers with lower fees, depending on their specific needs.

#### Slow ETH deposits

Below is a diagram showing the 'slow' ETH bridging pathway. The L2 ETH bridge requires the latest L1 state root (containing the L1 signal) to verify the L1 storage proof.

![Slow](<Taiko Messaging.png>)

#### Fast ETH deposits

In contrast here is diagram showing the 'fast' signalling pathway. In this scenario the L2 ETH bridge can just verify that the signal is present in the L2 `receivedSignal` mapping instead of relying on the L1 state root. This mapping would have already been filled when the block was proposed.

![Fast](Fast.png)

In either case however, the message being stored consist of the `destinationChainId`, `nonce` (to prevent storage collision), `from` address, `to` address and `value` (amount of ETH). These values form a `ValueTicket`. The `ValueTicket` is hashed and stored as the `value` of the signal.

### Token Bridges

The current repository does not include token-specific bridges (as these are more application-specific and not considered 'core' to the protocol). However, these would presumably use the same mechanisms as the ETH bridge, leveraging both fast and slow signaling as appropriate for different token transfer scenarios.

Popular token bridges (e.g. erc20, erc721) will perhaps be added at a later date.

## Future Considerations

- **Merging fast and slow pathways in the SS**: Creating a unified signal service that deals with both the fast and slow signals.
- **L2 → L1 fast withdrawals using solver [network](https://ethresear.ch/t/fast-and-slow-l2-l1-withdrawals/21161)**: Implementing a network of solvers which could dramatically improve withdrawal times from L2 to L1.
- **Signal storage optimisation**s: Currently, signals cannot be cancelled and are stored indefinitely. We could explore allowing cancellable signals or reusing storage to improve efficiency.
- **Cross-rollup communication**: Extending the signalling mechanism to enable direct communication between different L2 solutions
