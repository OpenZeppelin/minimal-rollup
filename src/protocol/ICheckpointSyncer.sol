// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";

/// @dev Synchronize checkpoints from different chains
///
/// A checkpoint is any value (typically a state root) that uniquely identifies the state of a chain at a
/// specific height (i.e. an incremental identifier like a blockNumber, publicationId or even a timestamp).
/// Only a trusted syncer can sync checkpoints. For example, only the `CheckpointTracker` can sync roots on the L1 and
/// the anchor can sync blockhash on the L2.
interface ICheckpointSyncer {
    /// @dev A new `checkpoint` has been synced for `chainId`.
    event CheckpointSynced(bytes32 checkpoint, uint64 chainId);

    /// @dev Emitted when the trusted syncer is updated.
    event TrustedSyncerUpdated(address newTrustedSyncer);

    /// @dev The caller is not a recognized checkpoint tracker.
    error UnauthorizedCheckpointTracker();

    /// @dev Returns the current trusted syncer.
    function trustedSyncer() external view returns (address);

    /// @dev Sets a new trusted syncer.
    /// @param newTrustedSyncer The new trusted syncer address
    function setTrustedSyncer(address newTrustedSyncer) external;

    /// @dev Returns the checkpoint at the given `height`.
    /// @param height The height of the checkpoint
    function checkpointAt(uint64 height) external view returns (bytes32 checkpoint);

    /// @dev Syncs a checkpoint.
    /// @param height The height of the checkpoint
    /// @param checkpoint The checkpoint to sync
    function syncCheckpoint(uint64 height, bytes32 checkpoint) external;
}
