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

### Cross-chain signal verification

Each commitment is saved under a `height` identifier (for example, the block number), which ensures they are never overwritten and that signal proofs do not expire, even if they reference an old commitment. This is acceptable because signals are never deleted and the proofs merely indicate that the signal was sent on the source chain at some point in the past.

Anyone can prove the existence of a source chain signal by:

- specifying the signal's `sender` and `value`.
- specifying the `stateRoot`, `blockHash`, `height` and publisher address that identifies the relevant commitment.
- providing the Merkle proof to identify the `SignalService` account (and corresponding storage root) underneath the given `stateRoot`.
    - note that we are locating the source chain `SignalService` contract within the source chain's state root, but we assume it will have the same address as the destination chain `SignalService`.
- providing the Merkle proof to identify the relevant storage location under the storage root, and confirming it is set to `true`.

## Application Examples

### ETH Bridge

The `ETHBridge` contract can be used to transfer ETH between mainnet and the rollup. It is designed to be deployed on both chains, where:

- the mainnet instance is configured to trust commitments posted by the `CheckpointTracker`.
- the rollup instance is configured to trust commitments posted by the anchor contract.
- the rollup instance is prefunded with infinite ETH. All circulating ETH on the rollup will originate from this contract.

ETH transfers are implemented as a simple wrapper over the cross-chain mechanism provided by the `SignalService`:

- user funds are deposited on the source chain bridge, which defines a message containing the deposit details.
- the bridge records the corresponding signal in its local `SignalService`.
- once the commitment is published on the destination chain, the recipient can prove the existence of the deposit and retrieve the funds.

### Token Bridges

This repository includes contracts to bridge ERC-20, ERC-721 and ERC-1155 tokens. These are application-level contracts with no special privileges and are provided for convenience.

The transfer flow is slightly more complicated:

- for each source token, anyone can deploy a bridged token contract on the other chain. These tokens will have standard functionality (without replicating any bespoke behavior of the source token contract) and can be minted and burned by the destination chain's bridge.
- in this way, withdrawals and deposits of the bridged token are implemented as mint and burn operations on the destination chain. The source token is still transferred to and from the bridge on the source chain.

Nevertheless, the cross-chain signalling mechanism is the same as for the ETH bridge.
