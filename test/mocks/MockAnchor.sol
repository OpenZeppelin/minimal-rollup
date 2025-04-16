// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICommitmentStore} from "src/protocol/ICommitmentStore.sol";

contract MockAnchor {
    ICommitmentStore public immutable commitmentStore;

    constructor(address _commitmentStore) {
        commitmentStore = ICommitmentStore(_commitmentStore);
    }

    /// @notice Anchor doesnt do anything, it just stores the commitment
    function anchor(uint256 _anchorBlockId, bytes32 _anchorBlockHash) external {
        // WARN: Here we are committing the L1 state root not block hash
        commitmentStore.storeCommitment(block.chainid, _anchorBlockId, _anchorBlockHash);
    }
}
