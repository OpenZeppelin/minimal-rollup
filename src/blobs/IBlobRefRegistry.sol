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

    /// @notice Retrieves blob data for given blob indices and saves their hash
    /// @param blobIdxs Array of blob indices to retrieve
    /// @return ref The retrieved blob data including block number and blob hashes
    /// @return refHash The keccak256 hash of the encoded blob source
    /// @dev Should revert if any blob index is invalid or if no blobs are provided
    function getRefAndSaveHash(uint256[] calldata blobIdxs) external returns (BlobRef memory ref, bytes32 refHash);

    /// @notice Retrieves blob data for given blob indices without saving
    /// @param blobIdxs Array of blob indices to retrieve
    /// @return The blob data including block number and blob hashes
    /// @dev Should revert if any blob index is invalid or if no blobs are provided
    function getRef(uint256[] calldata blobIdxs) external view returns (BlobRef memory);

    /// @notice Checks if a blob reference has been previously saved
    /// @param ref The blob reference to check
    /// @return True if the blob reference hash exists in the registry, false otherwise
    function isRefKnown(BlobRef memory ref) external view returns (bool);
}
