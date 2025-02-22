// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IBlobRegistry.sol";

/// @title BlobRegistry
contract BlobRegistry is IBlobRegistry {
    /// @dev A mapping of the hash of a blob source to the timestamp when it was saved
    mapping(bytes32 sourceHash => uint256 timestamp) private _savedSourceHashes;

    /// @inheritdoc IBlobRegistry
    function getAndSaveSourceHash(uint256[] calldata blobIdxs)
        external
        returns (BlobSource memory blobSource, bytes32 sourceHash)
    {
        blobSource = _get(blobIdxs);
        sourceHash = _saveSourceHash(blobSource);
    }

    /// @inheritdoc IBlobRegistry
    function get(uint256[] calldata blobIdxs) external view returns (BlobSource memory) {
        return _get(blobIdxs);
    }

    /// @inheritdoc IBlobRegistry
    function isKnown(BlobSource memory blobSource) external view returns (bool) {
        return _savedSourceHashes[keccak256(abi.encode(blobSource))] != 0;
    }

    /// @dev Saves the hash of a blob source to the registry
    /// @param blobSource The blob source to save
    /// @return The hash of the blob source
    function _saveSourceHash(BlobSource memory blobSource) private returns (bytes32) {
        bytes32 hash = keccak256(abi.encode(blobSource));
        _savedSourceHashes[hash] = block.timestamp;

        return hash;
    }

    /// @dev Retrieves the blob source for given blob indices
    /// @param blobIdxs The indices of the blobhashes to retrieve
    /// @return The blob source constructed from the block's number and the list of blob hashes
    function _get(uint256[] calldata blobIdxs) private view returns (BlobSource memory) {
        uint256 nBlobs = blobIdxs.length;
        require(nBlobs != 0, "No blobs provided");

        bytes32[] memory blobhashes = new bytes32[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobhashes[i] = blobhash(blobIdxs[i]);
            require(blobhashes[i] != 0, "Blob not found");
        }

        return BlobSource(block.number, blobhashes);
    }
}
