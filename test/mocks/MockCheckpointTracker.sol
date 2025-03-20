// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "src/protocol/interfaces/ICheckpointTracker.sol";

contract MockCheckpointTracker is ICheckpointTracker {
    bytes32 public provenHash;

    constructor() {
        // Set the initial proven hash to the zero checkpoint
        Checkpoint memory zeroCheckpoint = Checkpoint({publicationId: 0, commitment: bytes32(0)});
        provenHash = keccak256(abi.encode(zeroCheckpoint));
    }

    /// @notice Do nothing. All checkpoints and proofs are accepted.
    function proveTransition(
        Checkpoint calldata start,
        Checkpoint calldata end,
        uint256 numPublications,
        bytes calldata proof
    ) external {}

    /// @notice Helper to set the proven hash for easier testing
    /// @param checkpoint the checkpoint to set as proven, that will be hashed and stored as the proven hash
    function setProvenHash(Checkpoint memory checkpoint) external {
        provenHash = keccak256(abi.encode(checkpoint));
    }
}
