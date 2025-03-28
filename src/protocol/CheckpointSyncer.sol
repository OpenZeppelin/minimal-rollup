// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointSyncer} from "./ICheckpointSyncer.sol";
import {ICheckpointTracker} from "./ICheckpointTracker.sol";

/// @dev Tracks and synchronizes checkpoints from different chains using their chainId.
abstract contract CheckpointSyncer is ICheckpointSyncer {
    address private immutable checkpointTracker;

    /// @dev Sets the checkpoint tracker.
    constructor(address _checkpointTracker) {
        _checkpointTracker = checkpointTracker;
    }

    /// @inheritdoc ICheckpointSyncer
    function getCheckpointId(ICheckpointTracker.Checkpoint memory checkpoint, uint64 chainId)
        public
        pure
        virtual
        returns (bytes32 id)
    {
        id = _generateId(checkpoint, chainId);
    }

    /// @inheritdoc ICheckpointSyncer
    function syncCheckpoint(ICheckpointTracker.Checkpoint memory checkpoint, uint64 chainId)
        public
        virtual
        returns (bytes32 id)
    {
        require(msg.sender == checkpointTracker, UnauthorizedCheckpointTracker());
        id = getCheckpointId(checkpoint, chainId);
        emit CheckpointSynced(checkpoint, chainId);
    }

    /// @inheritdoc ICheckpointSyncer
    function verifyCheckpoint(
        ICheckpointTracker.Checkpoint memory checkpoint,
        uint64 chainId,
        bytes32 root,
        bytes[] memory accountProof,
        bytes[] memory proof
    ) public view virtual returns (bytes32 id);

    function _generateId(ICheckpointTracker.Checkpoint memory checkpoint, uint64 chainId)
        internal
        pure
        returns (bytes32 id)
    {
        return keccak256(abi.encode(chainId, checkpoint));
    }
}
