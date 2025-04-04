// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {ICommitmentStore} from "./ICommitmentStore.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev Base contract for storing commitments.
abstract contract CommitmentStore is ICommitmentStore, Ownable {
    using SafeCast for uint256;

    address private _authorizedCommitter;

    mapping(uint256 height => bytes32 commitment) private _commitments;

    /// @param _rollupOperator The address of the rollup operator
    constructor(address _rollupOperator) Ownable(_rollupOperator) {}

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
    function setAuthorizedCommitter(address newAuthorizedCommitter) external virtual onlyOwner {
        require(newAuthorizedCommitter != address(0), EmptyCommitter());
        _authorizedCommitter = newAuthorizedCommitter;
        emit AuthorizedCommitterUpdated(newAuthorizedCommitter);
    }

    /// @inheritdoc ICommitmentStore
    function commitmentAt(uint256 height) public view virtual returns (bytes32) {
        return _commitments[height];
    }

    /// @inheritdoc ICommitmentStore
    function storeCommitment(uint256 height, bytes32 commitment) external virtual onlyAuthorizedCommitter {
        _commitments[height] = commitment;
        emit CommitmentStored(block.chainid.toUint64(), commitment, height);
    }

    /// @dev Internal helper to validate the authorizedCommitter.
    function _checkAuthorizedCommitter(address caller) internal view {
        require(caller == _authorizedCommitter, UnauthorizedCommitter());
    }
}
