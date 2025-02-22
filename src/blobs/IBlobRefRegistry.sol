// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IBlobRefRegistry
/// @notice Interface for accessing and registering blob hashes from transactions
interface IBlobRefRegistry {
    /// @dev Struct containing blob hashes from a specific block
    /// @param blockNumber The block number where the blobs were included
    /// @param blobs Array of blob hashes
    struct BlobRef {
        uint256 blockNumber;
        bytes32[] blobhashes;
    }

    /// @notice Validates blobs at given indices, return a ref object, then save the ref hash for later usage
    /// @param blobIndices A bytes32 value encoding up to 16 blob indices as uint16 values. The right-most uint16
    /// represents the first blob index. Indices are processed from right to left, stopping at the first 0 index
    /// encountered (excluding the right-most index).
    /// @return ref The BlobRef struct containing the block number and the array of blob hashes.
    /// @return refHash The keccak256 hash of the encoded blob ref
    /// @dev Should revert if any blob index is invalid or if no blobs are provided
    function getRefAndSaveHash(bytes32 blobIndices) external returns (BlobRef memory ref, bytes32 refHash);

    /// @notice Validates blobs at given indices and return a ref object
    /// @param blobIndices A bytes32 value encoding up to 16 blob indices as uint16 values. The right-most uint16
    /// represents the first blob index. Indices are processed from right to left, stopping at the first 0 index
    /// encountered (excluding the right-most index).
    /// @return The blob data including block number and blob hashes
    /// @dev Should revert if any blob index is invalid or if no blobs are provided
    function getRef(bytes32 blobIndices) external view returns (BlobRef memory);

    /// @notice Checks if a blob reference has been previously saved
    /// @param ref The blob ref to check
    /// @return True if the blob ref hash exists in the registry, false otherwise
    function isRefKnown(BlobRef memory ref) external view returns (bool);
}
