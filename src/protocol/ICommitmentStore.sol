// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";

/// @dev Stores commitments from different chains.
///
/// A commitment is any value that uniquely identifies the state of a chain at a specific height (i.e. an incremental
/// identifier like a blockNumber, publicationId or even a timestamp). If using the `CommitmentStore` for messaging it
/// is also helpful to be able to derive a value from the commitment that allows to prove messages across chains.
///
/// There is no access control so only commitments from trusted sources should be used.
/// For example, L2 contracts should use L1 commitments saved by the anchor contract and L1 contracts should use L2
/// commitments saved by the relevant `CheckpointTracker`.
interface ICommitmentStore {
    /// @dev A new `commitment` has been stored by `source` at a specified `height`.
    event CommitmentStored(address indexed source, uint256 indexed height, bytes32 commitment);

    /// @notice Returns the commitment at the given `height`.
    /// @dev If the commitment does not exist at the given `height`, it returns zero.
    /// @param source The source address for the saved commitment
    /// @param height The height of the commitment
    function commitmentAt(address source, uint256 height) external view returns (bytes32 commitment);

    /// @notice Stores a commitment attributed to `msg.sender`
    /// @param height The height of the commitment
    /// @param commitment The commitment to store
    function storeCommitment(uint256 height, bytes32 commitment) external;
}
