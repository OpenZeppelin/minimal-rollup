// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICheckpointTracker {
    struct Checkpoint {
        uint256 publicationId;
        bytes32 commitment;
    }

    /// @notice Emitted when a checkpoint is proven
    /// @param checkpointHash the hash of the proven checkpoint
    event CheckpointProven(bytes32 indexed checkpointHash);

    /// @notice Emitted when a transition is proven
    /// @param start the checkpoint before the transition
    /// @param end the checkpoint after the transition
    event TransitionProven(Checkpoint start, Checkpoint end);

    /// @notice Verifies a transition between two checkpoints. Update the latest `provenCheckpoint` if possible
    /// @param start The initial checkpoint before the transition
    /// @param end The final checkpoint after the transition
    /// @param proof Arbitrary data passed to the `verifier` contract to confirm the transition validity
    function proveTransition(Checkpoint calldata start, Checkpoint calldata end, bytes calldata proof) external;
}
