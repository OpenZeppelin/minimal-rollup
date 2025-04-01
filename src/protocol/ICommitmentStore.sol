// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";

/// @dev Stores commitments from different chains.
///
/// A commitment is any value (typically a state root) that uniquely identifies the state of a chain at a
/// specific height (i.e. an incremental identifier like a blockNumber, publicationId or even a timestamp).
/// Only an authorized committer can store commitments. For example, only the `CheckpointTracker` can store roots on the
/// L1,
/// and the anchor can store block hashes on the L2.
interface ICommitmentStore {
    /// @dev A new `commitment` has been stored for `chainId` at a specified `height`.
    event CommitmentStored(uint64 indexed chainId, bytes32 commitment, uint256 height);

    /// @dev Emitted when the authorized committer is updated.
    event AuthorizedCommitterUpdated(address newAuthorizedCommitter);

    /// @dev The caller is not a recognized authorized committer.
    error UnauthorizedCommitter();

    /// @dev Returns the current authorized committer.
    function authorizedCommitter() external view returns (address);

    /// @dev Sets a new authorized committer.
    /// @param newAuthorizedCommitter The new authorized committer address
    function setAuthorizedCommitter(address newAuthorizedCommitter) external;

    /// @dev Returns the latest commitment.
    function latestCommitment() external view returns (bytes32 commitment);

    /// @dev Returns the latest height.
    function latestHeight() external view returns (uint256 height);

    /// @dev Returns the commitment at the given `height`.
    /// @param height The height of the commitment
    function commitmentAt(uint256 height) external view returns (bytes32 commitment);

    /// @dev Stores a commitment.
    /// @param height The height of the commitment
    /// @param commitment The commitment to store
    function storeCommitment(uint256 height, bytes32 commitment) external;
}
