// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";

/// @dev Stores commitments from different chains.
///
/// A commitment is any value (typically a state root) that uniquely identifies the state of a chain at a
/// specific height (i.e. an incremental identifier like a blockNumber, publicationId or even a timestamp).
///
/// There is no access control so only commitments from trusted sources should be used.
/// For example, L2 contracts should use L1 commitments saved by the anchor contract and L1 contracts should use L2
/// commitments saved by the relevant `CheckpointTracker`.
interface ICommitmentStore {
    /// @dev A new `commitment` has been stored by `source` at a specified `height`.
    event CommitmentStored(address indexed source, uint256 indexed height, bytes32 commitment);

    /// @dev Returns the commitment at the given `height`.
    /// @param source The source address for the saved commitment
    /// @param height The height of the commitment
    function commitmentAt(address source, uint256 height) external view returns (bytes32 commitment);

    /// @dev Stores a commitment.
    /// @param height The height of the commitment
    /// @param commitment The commitment to store
    function storeCommitment(uint256 height, bytes32 commitment) external;
}
