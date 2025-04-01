// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {ICommitmentStore} from "./ICommitmentStore.sol";

abstract contract CommitmentStore is ICommitmentStore {
    address private _authorizedCommitter;

    mapping(uint256 height => bytes32 commitment) private _commitments;

    /// @dev Reverts if the caller is not the `authorizedCommitter`.
    modifier onlyAuthorizedCommitter() {
        _checkAuthorizedCommitter(msg.sender);
        _;
    }

    /// @inheritdoc ICommitmentStore
    function authorizedCommitter() public view virtual returns (address) {
        return _authorizedCommitter;
    }

    /// @inheritdoc ICommitmentStore
    function setAuthorizedCommitter(address newAuthorizedCommitter) external virtual {
        // WARN: ADD ACCESS CONTROL
        _authorizedCommitter = newAuthorizedCommitter;
        emit AuthorizedCommitterUpdated(newAuthorizedCommitter);
    }

    /// @inheritdoc ICommitmentStore
    function commitmentAt(uint256 height) public view virtual returns (bytes32 commitment) {
        return _commitments[height];
    }

    /// @inheritdoc ICommitmentStore
    function storeCommitment(uint256 height, bytes32 commitment) external virtual onlyAuthorizedCommitter {
        require(commitment != bytes32(0), "Commitment cannot be 0");
        _commitments[height] = commitment;
        emit CommitmentStored(commitment, uint64(block.chainid), height);
    }

    /// @dev Internal helper to validate the authorizedCommitter.
    function _checkAuthorizedCommitter(address caller) internal view {
        require(caller == _authorizedCommitter, UnauthorizedCommitter());
    }
}
