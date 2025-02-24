// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICheckpointTracker {
    struct Checkpoint {
        uint256 publicationId;
        bytes32 commitment;
    }

    /// @notice Emitted when a checkpoint is first seen
    /// @param publicationId The index of the publication for the commitment
    /// @param commitment The checkpoint commitment
    /// @param checkpointHash The hash of the checkpoint
    /// @dev The contract operates on checkpoint hashes. This event can be used to map it to the actual checkpoint.
    event CheckpointSeen(uint256 indexed publicationId, bytes32 indexed commitment, bytes32 indexed checkpointHash);

    /// @notice Emitted when a checkpoint is proven
    /// @param checkpointHash the hash of the proven checkpoint
    event CheckpointProven(bytes32 indexed checkpointHash);

    /// @notice Emitted when a transition is proven
    /// @param startCheckpointHash the hash of the checkpoint before the transition
    /// @param endCheckpointHash the hash of the checkpoint after the transition
    event TransitionProven(bytes32 indexed startCheckpointHash, bytes32 indexed endCheckpointHash);
}
