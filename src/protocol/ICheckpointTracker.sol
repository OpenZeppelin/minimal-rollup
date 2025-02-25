// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICheckpointTracker {
    struct Commitment {
        bytes32 blockHash;
        bytes32 stateRoot;
        bytes32 signalRoot;
    }

    struct Checkpoint {
        uint256 publicationId;
        Commitment commitment;
    }

    /// @notice Emitted when the proven checkpoint is updated
    /// @param checkpointHash the hash of the last proven checkpoint
    /// @param checkpoint the last proven checkpoint
    event CheckpointUpdated(bytes32 checkpointHash, Checkpoint checkpoint);

    /// @notice Emitted when a transition is proven
    /// @param startPublicationId The ID of the starting publication
    /// @param startCommitmentHash The hash of the starting commitment
    /// @param endCheckpoint The final checkpoint after the transition
    event TransitionProven(uint256 startPublicationId, uint256 startCommitmentHash, Checkpoint endCheckpoint);

    // /// @notice Verifies a transition between two checkpoints. Update the latest `provenCheckpoint` if possible
    /// @notice Verifies a transition between two checkpoints. Update the latest `provenCheckpoint` if possible
    /// @param startPublicationId The ID of the starting publication
    /// @param startCommitmentHash The hash of the starting commitment
    /// @param endCheckpoint The final checkpoint after the transition
    /// @param proof The proof to verify the transition
    function proveTransition(
        uint256 startPublicationId,
        uint256 startCommitmentHash,
        Checkpoint calldata endCheckpoint,
        bytes calldata proof
    ) external;
}
