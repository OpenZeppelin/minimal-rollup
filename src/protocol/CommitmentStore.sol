// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {ICommitmentStore} from "./ICommitmentStore.sol";

/// @dev Base contract for storing commitments.
/// Uses a circular buffer to store commitments, size is defined by `bufferLength`.
abstract contract CommitmentStore is ICommitmentStore {
    address private _authorizedCommitter;
    address private immutable _rollupOperator;
    uint256 private _latestHeight;

    mapping(uint256 index => bytes32 commitment) private _commitments;

    /// @param rollupOperator The address of the rollup operator
    constructor(address rollupOperator) {
        require(rollupOperator != address(0), EmptyRollupOperator());
        _rollupOperator = rollupOperator;
    }

    /// @dev Reverts if the caller is not the `authorizedCommitter`.
    modifier onlyAuthorizedCommitter() {
        _checkAuthorizedCommitter(msg.sender);
        _;
    }

    /// @notice Returns the size of the circular buffer.
    function bufferLength() public view virtual returns (uint256) {
        return 256;
    }

    /// @inheritdoc ICommitmentStore
    function authorizedCommitter() public view virtual returns (address) {
        return _authorizedCommitter;
    }

    /// @inheritdoc ICommitmentStore
    function setAuthorizedCommitter(address newAuthorizedCommitter) external virtual {
        require(msg.sender == _rollupOperator, OnlyRollupOperator());
        require(newAuthorizedCommitter != address(0), EmptyCommitter());
        _authorizedCommitter = newAuthorizedCommitter;
        emit AuthorizedCommitterUpdated(newAuthorizedCommitter);
    }

    /// @inheritdoc ICommitmentStore
    function latestCommitment() public view virtual returns (bytes32 commitment) {
        return _commitments[_latestHeight % bufferLength()];
    }

    /// @inheritdoc ICommitmentStore
    function latestHeight() public view virtual returns (uint256) {
        return _latestHeight;
    }

    /// @inheritdoc ICommitmentStore
    function commitmentAt(uint256 height) public view virtual returns (bytes32) {
        uint256 latestHeight_ = _latestHeight;
        require(height <= latestHeight_, HeightGreaterThanLatest());
        uint256 _bufferLength = bufferLength();
        require(latestHeight_ - height <= _bufferLength, CommitmentNotFound());
        uint256 index = height % _bufferLength;
        return _commitments[index];
    }

    /// @inheritdoc ICommitmentStore
    function storeCommitment(uint256 height, bytes32 commitment) external virtual onlyAuthorizedCommitter {
        // CHECK: These could be skipped as caller always checks them
        require(commitment != bytes32(0), "Commitment cannot be 0");
        require(height > _latestHeight, "Height must be greater than latest height");

        uint256 index = height % bufferLength();
        _commitments[index] = commitment;
        _latestHeight = height;

        emit CommitmentStored(uint64(block.chainid), commitment, height);
    }

    /// @dev Internal helper to validate the authorizedCommitter.
    function _checkAuthorizedCommitter(address caller) internal view {
        require(caller == _authorizedCommitter, UnauthorizedCommitter());
    }
}
