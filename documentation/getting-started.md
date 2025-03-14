# Minimal Rollup Protocol

The minimal rollup protocol is a set of smart contracts that define the core functionality of a [based](https://ethresear.ch/t/based-rollups-superpowers-from-l1-sequencing/15016) Ethereum L2 rollup. Bringing the following benefits:

- Minimize the infrastructure requirements to run a rollup (sequencing is done by L1 nodes), making it easier to deploy and maintain.
- L1 Liveness inheritance, meaning that the rollup can't be censored or stopped by a single entity.
- Maximize decentralization by allowing anyone to propose blocks and generate proofs.

To run a full L2 rollup node, you need to run a client (e.g. a piece of software that runs along with [an Ethereum client](https://github.com/NethermindEth/nethermind)). To get started with the protocol side, you can use install this library in your project and start building your rollup.

## Installation

```bash
forge install OpenZeppelin/minimal-rollup
```

## Library Usage

The minimal rollup is a composition of the various contracts. A basic version of a rollup can be created simply by inheriting from the `L1Rollup` contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/minimal-rollup/contracts/L1Rollup.sol";

contract MyRollup is L1Rollup {
    constructor(bytes32 genesisCommitment) L1Rollup(genesisCommitment) {}
}
```

NOTE: Implementing `L1Rollup#isValidTransition` and `L1Rollup#toCommitment` is required to make the contract functional. This is left to the implementation since different rollups can have different rules to decode a publication into a commitment and to validate a state transition for such commitment.

### Deposits

Some use cases of an L1 rollup require users to deposit funds into the rollup (e.g. to provide a liveness bond in a proving market). To support this, the library offers an extension of the `L1Rollup` that handles deposits:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {L1Rollup} from "@openzeppelin/minimal-rollup/contracts/extensions/L1Rollup.sol";
import {L1RollupDepositable} from "@openzeppelin/minimal-rollup/contracts/extensions/L1RollupDepositable.sol";

contract MyRollup is L1Rollup, L1RollupDepositable {
    constructor(bytes32 genesisCommitment) L1Rollup(genesisCommitment) {}
}
```

### Incentivizing Provers

Proving can be restricted to certain actors by overriding the `prove` function in the `L1Rollup` contract. This allows for a proving market to be implemented on top of the rollup:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {L1Rollup} from "@openzeppelin/minimal-rollup/contracts/L1Rollup.sol";

contract MyRollup is L1Rollup {
    constructor(bytes32 genesisCommitment) L1Rollup(genesisCommitment) {}

    function prove(bytes32[] calldata publications, bytes calldata proof) public {
        require(msg.sender == address(0x123), "Only the prover can prove");
        super.prove(publications, proof);
    }
}
```

Following this idea, you can implement a proving market that sets the prover address dynamically. An example of this is an ahead-of-time auction mechanism that allows provers to bid for the right to prove multiple publications for a rollup. To use it, inherit from the L1RollupProverMarket contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {L1Rollup} from "@openzeppelin/minimal-rollup/contracts/L1Rollup.sol";
import {L1RollupProverMarket} from "@openzeppelin/minimal-rollup/contracts/extensions/L1RollupProverMarket.sol";

contract MyRollup is L1Rollup, L1RollupProverMarket {
    constructor(bytes32 genesisCommitment) L1Rollup(genesisCommitment) {}
}
```
