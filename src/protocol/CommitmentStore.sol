// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICommitmentStore} from "./ICommitmentStore.sol";

/// @dev Base contract for storing commitments.
abstract contract CommitmentStore is ICommitmentStore {
    mapping(address source => mapping(uint256 height => bytes32 commitment)) private _commitments;

    /// @inheritdoc ICommitmentStore
    function commitmentAt(address source, uint256 height) public view virtual returns (bytes32) {
        return _commitments[source][height];
    }

    /// @inheritdoc ICommitmentStore
    function storeCommitment(uint256 height, bytes32 commitment) external virtual {
        _commitments[msg.sender][height] = commitment;
        emit CommitmentStored(msg.sender, height, commitment);
    }
}
