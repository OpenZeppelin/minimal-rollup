// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointSyncer} from "./ICheckpointSyncer.sol";
import {ICheckpointTracker} from "./ICheckpointTracker.sol";

abstract contract CheckpointSyncer is ICheckpointSyncer {
    address private _trustedSyncer;

    mapping(uint256 height => bytes32 checkpoint) private _checkpoints;

    /// @dev Reverts if the caller is not the `trustedSyncer`.
    modifier onlyTrustedSyncer() {
        _checkTrustedSyncer(msg.sender);
        _;
    }

    /// @inheritdoc ICheckpointSyncer
    function trustedSyncer() public view virtual returns (address) {
        return _trustedSyncer;
    }

    /// @inheritdoc ICheckpointSyncer
    function setTrustedSyncer(address newTrustedSyncer) external virtual {
        // WARN: ADD ACCESS CONTROL
        _trustedSyncer = newTrustedSyncer;
        emit TrustedSyncerUpdated(newTrustedSyncer);
    }

    /// @inheritdoc ICheckpointSyncer
    function checkpointAt(uint256 height) public view virtual returns (bytes32 checkpoint) {
        return _checkpoints[height];
    }

    /// @inheritdoc ICheckpointSyncer
    function syncCheckpoint(uint256 height, bytes32 checkpoint) external virtual onlyTrustedSyncer {
        require(checkpoint != bytes32(0), "Checkpoint cannot be 0");
        //TODO: Should we check height > previous height? would require more storage
        /// However the calling contracts all check this fact so can skip
        _checkpoints[height] = checkpoint;
        emit CheckpointSynced(checkpoint, uint64(block.chainid), height);
    }

    /// @dev Internal helper to validate the trusted syncer.
    function _checkTrustedSyncer(address caller) internal view {
        require(caller == _trustedSyncer, "UnauthorizedCheckpointTracker");
    }
}
