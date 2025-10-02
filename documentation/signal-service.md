# Signals

The `SignalService` contract allows users to _signal_ that a message was recorded on a source chain, so this fact can later be proven on a destination chain. The message itself is not recorded and needs to be reproduced and validated on the destination chain.

## Data Flow

### Preparation

The `SignalService` contract should be deployed (or predeployed) at the same address on multiple chains.

### Signalling

Any user can signal an arbitrary `bytes32` value to represent the message. This could be a hash of the message or any other value type that can be stored in a single EVM word. The contract will use the [ERC-7201](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/ca7a4e39de0860bbaadf95824207886e6de9fa64/contracts/utils/SlotDerivation.sol#L4) standard to derive a pseudorandom storage slot namespaced to the `msg.sender` and save the boolean `true` in that location. This prevents collisions between signals recorded by different users or contracts, but does allow the same address to repeatedly send the same signal.

Signals cannot be deleted and remain in storage indefinitely. Therefore, anyone can check the corresponding storage location to validate whether a particular address has signalled a particular value on that chain.

### Importing commitments

The `SignalService` contract defines a _commitment_ as `keccak256(abi.encode(stateRoot, blockHash))`, which represents the state of another chain at some block height.

Any address can post commitments, so the validity of the commitment is inferred from the credibility of the publishing address. For example:
- the `CheckpointTracker` contract is responsible for confirming a rollup's validity proofs on the Ethereum mainnet. It then posts the validated checkpoints to the mainnet `SignalService`. If multiple rollups used the same contract, the relevant chain could be identified by the particular `CheckpointTracker` contract that posted the commitment.
- the L2 anchor contract accepts a mainnet header (validated by the rollup nodes) and posts the corresponding checkpoint to the L2 `SignalService`.
