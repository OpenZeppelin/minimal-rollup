// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {ICommitmentStore} from "./ICommitmentStore.sol";

/// @dev Base contract for storing commitments.
/// Uses a circular buffer to store commitments, size is defined by `bufferLength`.
abstract contract CommitmentStore is ICommitmentStore {
    address private _authorizedCommitter;

    mapping(uint256 index => bytes32 commitment) private _commitments;
    uint256 private _latestHeight;

    /// @dev Reverts if the caller is not the `authorizedCommitter`.
    modifier onlyAuthorizedCommitter() {
        _checkAuthorizedCommitter(msg.sender);
        _;
    }

    /// @notice Returns the size of the circular buffer (can override).
    function bufferLength() public view virtual returns (uint256) {
        return 256;
    }

    /// @inheritdoc ICommitmentStore
    function authorizedCommitter() public view virtual returns (address) {
        return _authorizedCommitter;
    }

    /// @inheritdoc ICommitmentStore
    function setAuthorizedCommitter(address newAuthorizedCommitter) external virtual {
        // WARN: ADD ACCESS CONTROL
        require(newAuthorizedCommitter != address(0), "Empty Committer");
        _authorizedCommitter = newAuthorizedCommitter;
        emit AuthorizedCommitterUpdated(newAuthorizedCommitter);
    }

    /// @inheritdoc ICommitmentStore
    function latestCommitment() public view virtual returns (bytes32 commitment) {
        return _commitments[_latestHeight % bufferLength()];
    }

    /// @inheritdoc ICommitmentStore
    function latestHeight() public view virtual returns (uint256 height) {
        return _latestHeight;
    }

    /// @inheritdoc ICommitmentStore
    function commitmentAt(uint256 height) public view virtual returns (bytes32 commitment) {
        uint256 latestHeight_ = _latestHeight;
        require(height <= latestHeight_, "Height is greater than latest height");
        uint256 _bufferLength = bufferLength();
        require(latestHeight_ - height <= _bufferLength, "Commitment not found");
        uint256 index = height % _bufferLength;
        return _commitments[index];
    }

    /// @inheritdoc ICommitmentStore
    function storeCommitment(uint256 height, bytes32 commitment) external virtual onlyAuthorizedCommitter {
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
