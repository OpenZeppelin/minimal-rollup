// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";

/// @dev Synchronize checkpoints from different chains using their chainId.
///
/// A checkpoint is any value (typically a state root) that uniquely identifies the state of the rollup at an
/// specific height (i.e. an incremental identifier like a blockNumber, publicationId or even a timestamp).
///
/// Each checkpoint is identified by an id composed by the chainId, height and checkpoint itself.
interface ICheckpointSyncer {
    /// @dev A new `checkpoint` has been synced for `chainId`.
    event CheckpointSynced(ICheckpointTracker.Checkpoint checkpoint, uint64 chainId);

    /// @dev The caller is not a recognized checkpoint tracker.
    error UnauthorizedCheckpointTracker();

    /// @dev checkpoint identifier.
    function getCheckpointId(ICheckpointTracker.Checkpoint memory checkpoint, uint64 chainId)
        external
        pure
        returns (bytes32 id);

    /// @dev Syncs a checkpoint.
    function syncCheckpoint(ICheckpointTracker.Checkpoint memory checkpoint, uint64 chainId)
        external
        returns (bytes32 id);

    /// @dev Verifies that a `checkpoint` is valid for the provided `chainId`, `height` and `root`.
    /// The `root` MUST be trusted.
    function verifyCheckpoint(
        ICheckpointTracker.Checkpoint memory checkpoint,
        uint64 chainId,
        bytes32 root,
        bytes[] memory accountProof,
        bytes[] memory proof
    ) external view returns (bytes32 id);
}
