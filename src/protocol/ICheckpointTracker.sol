// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICheckpointTracker {
    struct Checkpoint {
        uint256 publicationId;
        bytes32 commitment;
    }

    /// @notice Emitted when the proven checkpoint is updated
    /// @param checkpointHash the hash of the last proven checkpoint
    event CheckpointUpdated(bytes32 indexed checkpointHash);

    /// @notice Emitted when a transition is proven
    /// @param start the checkpoint before the transition
    /// @param end the checkpoint after the transition
    event TransitionProven(Checkpoint start, Checkpoint end);

    /// @return _ The hash of the last proven checkpoint
    function provenHash() external view returns (bytes32);

    /// @notice Verifies a transition between two checkpoints. Update the latest `provenCheckpoint` if possible
    /// @param start The initial checkpoint before the transition
    /// @param end The final checkpoint after the transition
    /// @param proof Arbitrary data passed to the `verifier` contract to confirm the transition validity
    function proveTransition(Checkpoint calldata start, Checkpoint calldata end, bytes calldata proof) external;
}
