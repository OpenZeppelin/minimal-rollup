## Normal ‘slow’ Message Passing

In our current protocol, signalling is performed by storing a message at a specific storage slot, then, once the L1 state root is accessible on the L2, executing a storage proof to verify that value exists. This proof can then trigger then certain logic, such as minting tokens.

This is process is described by this diagram.

![Image](https://github.com/user-attachments/assets/5c27c6bc-cdd5-4964-8245-f5ae3f5b0272)

Currently each application is responsible for their own signalling (i.e. there is no central storage of all signals). This means any potential relaying must be done on an app by app basis. We only provide a standard signalling library to store and verify signals on chain.

This approach works well, but has some latency since the latest L1 state root in the case of Taiko is only accessible when the L2 proposer submits a new publication to the L1 and includes a new anchor tx to the L2.

## Same Slot L1 → L2 Message Passing

The signal service (SS) is used for cases where the message is to be sent within the same slot. This [design](https://ethresear.ch/t/same-slot-l1-l2-message-passing/21186) is the one proposed by Nethermind. The basic idea is as follows:

1. The proposer listens to any signals being stored on the L1 SS
2. The proposer (during his allocated slot) can selectively inject L1 → L2 signals when proposing a batch in `publish` function.
3. The inbox contract will verify that the Signals exist in the SS’s storage.
4. A trusted entity (owned by the rollup) will then call `receiveSignal` on the L2 SS. This will fill a mapping of `_receivedSignals` to true (signal —> true)
5. Any application that requires same slot signalling will just verify the signal is found in the `_receivedSignals` mapping i.e. they don’t need to provide a storage proof

## Future Considerations

- Merging fast and slow in the SS
- L2 → L1 fast withdrawals using solver [network](https://ethresear.ch/t/fast-and-slow-l2-l1-withdrawals/21161)
- Currently all signals cannot be cancelled and are stored indefinitely - perhaps we could look into allowing cancellable signals / reusing storage

## Questions

- Usefulness of commitment syncer - how is this currently being used to get a trusted root.
- L2 → L1 messaging
