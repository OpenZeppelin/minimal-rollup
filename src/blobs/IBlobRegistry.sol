// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IBlobRegistry
/// @notice Interface for accessing and registering blob hashes from transactions
interface IBlobRegistry {
    /// @dev Struct containing blob hashes from a specific block
    /// @param blockNumber The block number where the blobs were included
    /// @param blobs Array of blob hashes
    struct BlobSource {
        uint256 blockNumber;
        bytes32[] blobhashes;
    }

    /// @notice Retrieves blob data for given blob indices and saves their hash
    /// @param blobIdxs Array of blob indices to retrieve
    /// @return blobSource The retrieved blob data including block number and blob hashes
    /// @return hash The keccak256 hash of the encoded blob source
    /// @dev Should revert if any blob index is invalid or if no blobs are provided
    function getAndSaveHash(uint256[] calldata blobIdxs)
        external
        returns (BlobSource memory blobSource, bytes32 sourceHash);

    /// @notice Retrieves blob data for given blob indices without saving
    /// @param blobIdxs Array of blob indices to retrieve
    /// @return The blob data including block number and blob hashes
    /// @dev Should revert if any blob index is invalid or if no blobs are provided
    function get(uint256[] calldata blobIdxs) external view returns (BlobSource memory);

    /// @notice Checks if a blob source has been previously saved
    /// @param blobSource The blob source to check
    /// @return True if the blob source hash exists in the registry, false otherwise
    function isKnown(BlobSource memory blobSource) external view returns (bool);
}
