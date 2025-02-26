// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @dev Synchronize commitments from different chains using their chainId.
///
/// A commitment is any value (typically a state root) that uniquely identifies the state of the rollup at an
/// specific height (i.e. an incremental identifier like a blockNumber, publicationId or even a timestamp).
///
/// Each commitment is identified by an id composed by the chainId, height and commitment itself.
interface ICommitmentSyncer {
    /// @dev A new `commitment` has been synced for `chainId` at `height`.
    event CommitmentSynced(uint64 indexed chainId, uint64 indexed height, bytes32 commitment);

    /// @dev The commitment verification failed.
    error InvalidCommitment();

    /// @dev Commitment identifier.
    function id(uint64 chainId, uint64 height, bytes32 commitment) external pure returns (bytes32 value);

    /// @dev Get commitment at a particular `height` for `chainId`.
    function commitmentAt(uint64 chainId, uint64 height) external view returns (bytes32 commitment);

    /// @dev Get the latest commitment for a `chainId`.
    function latestCommitment(uint64 chainId) external view returns (bytes32 commitment);

    /// @dev Get the latest commitment height for a `chainId`.
    function latestHeight(uint64 chainId) external view returns (uint64 height);

    /// @dev Verifies that a `commitment` is valid for the provided `chainId`, `height` and `root`.
    /// The `root` MUST be trusted.
    function verifyCommitment(uint64 chainId, uint64 height, bytes32 commitment, bytes32 root, bytes[] calldata proof)
        external
        view
        returns (bool valid);

    /// @dev Syncs a `commitment` as long as it's a valid one.
    /// The `root` MUST be trusted.
    function syncCommitment(uint64 chainId, uint64 height, bytes32 commitment, bytes32 root, bytes[] calldata proof)
        external;
}
