# Signals

The `SignalService` contract allows users to _signal_ that a message was recorded on a source chain, so this fact can later be proven on a destination chain. The message itself is not recorded and needs to be reproduced and validated on the destination chain.

## Data Flow

### Preparation

The `SignalService` contract should be deployed (or predeployed) at the same address on multiple chains.

### Signalling

Any user can signal an arbitrary `bytes32` value to represent the message. This could be a hash of the message or any other value type that can be stored in a single EVM word. The contract will use the [ERC-7201](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/ca7a4e39de0860bbaadf95824207886e6de9fa64/contracts/utils/SlotDerivation.sol#L4) standard to derive a pseudorandom storage slot namespaced to the `msg.sender` and save the boolean `true` in that location. This prevents collisions between signals recorded by different users or contracts, but does allow the same address to repeatedly send the same signal.

Signals cannot be deleted, and remain in storage indefinitely. Therefore, anyone can check the corresponding storage location to validate whether a particular address has signalled a particular value.
