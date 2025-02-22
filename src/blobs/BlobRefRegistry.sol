// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IBlobRefRegistry.sol";

/// @title BlobRefRegistry
contract BlobRefRegistry is IBlobRefRegistry {
    /// @dev A mapping of the hash of a blob ref to the timestamp when it was saved
    mapping(bytes32 refHash => uint256 timestamp) private _savedRefHashes;

    /// @inheritdoc IBlobRefRegistry
    function getRefAndSaveHash(uint256[] calldata blobIndices) external returns (BlobRef memory ref, bytes32 refHash) {
        ref = _getRef(blobIndices);
        refHash = _saveRefHash(ref);
    }

    /// @inheritdoc IBlobRefRegistry
    function getRef(uint256[] calldata blobIndices) external view returns (BlobRef memory) {
        return _getRef(blobIndices);
    }

    /// @inheritdoc IBlobRefRegistry
    function isRefKnown(BlobRef memory ref) external view returns (bool) {
        return _savedRefHashes[keccak256(abi.encode(ref))] != 0;
    }

    /// @dev Saves the hash of a blob ref to the registry
    /// @param ref The blob ref to save
    /// @return The hash of the blob source
    function _saveRefHash(BlobRef memory ref) private returns (bytes32) {
        bytes32 hash = keccak256(abi.encode(ref));
        _savedRefHashes[hash] = block.timestamp;
        return hash;
    }

    /// @dev Retrieves the blob ref for given blob indices
    /// @param blobIndices The indices of the blobhashes to retrieve
    /// @return The blob ref constructed from the block's number and the list of blob hashes
    function _getRef(uint256[] calldata blobIndices) private view returns (BlobRef memory) {
        uint256 nBlobs = blobIndices.length;
        require(nBlobs != 0, "No blobs provided");

        bytes32[] memory blobhashes = new bytes32[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobhashes[i] = blobhash(blobIndices[i]);
            require(blobhashes[i] != 0, "Blob not found");
        }

        return BlobRef(block.number, blobhashes);
    }
}
