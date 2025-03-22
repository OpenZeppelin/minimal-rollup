// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICheckpointTracker {
    struct Checkpoint {
        uint256 publicationId;
        bytes32 commitment;
    }

    /// @notice Emitted when the proven checkpoint is updated
    /// @param publicationId the publication id of the last proven checkpoint
    /// @param commitment the commitment of the last proven checkpoint
    event CheckpointUpdated(uint256 indexed publicationId, bytes32 commitment);

    /// @notice Emitted when a transition is proven
    /// @param start the checkpoint before the transition
    /// @param end the checkpoint after the transition
    event TransitionProven(Checkpoint start, Checkpoint end);

    /// @return _ The last proven checkpoint
    function getProvenCheckpoint() external view returns (Checkpoint memory);

    /// @notice Verifies a transition between two checkpoints. Update the latest `provenCheckpoint` if possible
    /// @param start The initial checkpoint before the transition
    /// @param end The final checkpoint after the transition
    /// @param numPublications The number of publications that need to be processed between the two checkpoints.
    /// Note that this is not necessarily (end.publicationId - start.publicationId) because there could be irrelevant
    /// publications.
    /// @param proof Arbitrary data passed to the `verifier` contract to confirm the transition validity
    function proveTransition(
        Checkpoint calldata start,
        Checkpoint calldata end,
        uint256 numPublications,
        bytes calldata proof
    ) external;
}
