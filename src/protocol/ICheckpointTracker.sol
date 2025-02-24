// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICheckpointTracker {
    struct Checkpoint {
        uint256 publicationId;
        bytes32 commitment;
    }

    /// @notice Emitted when a checkpoint is proven
    /// @param publicationId the index of the publication at which the commitment was proven
    /// @param commitment the checkpoint commitment that was proven
    event CheckpointProven(uint256 indexed publicationId, bytes32 indexed commitment);

    /// @notice Emitted when a transition is proven
    /// @param startPublicationId the index of the publication before the transition
    /// @param startCommitment the checkpoint at the start of the transition
    /// @param endPublicationId the index of the last publication in the transition
    /// @param endCommitment the checkpoint after the transition
    event TransitionProven(
        uint256 indexed startPublicationId,
        bytes32 indexed startCommitment,
        uint256 indexed endPublicationId,
        bytes32 endCommitment
    );
}
