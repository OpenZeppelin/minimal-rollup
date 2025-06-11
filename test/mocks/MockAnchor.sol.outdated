// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICommitmentStore} from "src/protocol/ICommitmentStore.sol";

contract MockAnchor {
    ICommitmentStore public immutable commitmentStore;

    constructor(address _commitmentStore) {
        commitmentStore = ICommitmentStore(_commitmentStore);
    }

    /// @notice Anchor doesnt do anything, it just stores the commitment
    function anchor(uint256 _anchorBlockId, bytes32 _commitment) external {
        // TODO: The real anchor contract hashes the block header to verify the block hash,
        // but here we just store the commitment directly
        // Where commitment is the keccak256(abi.encode(stateRoot, blockHash))
        commitmentStore.storeCommitment(_anchorBlockId, _commitment);
    }
}
