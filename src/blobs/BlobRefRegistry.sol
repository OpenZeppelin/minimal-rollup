// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IBlobRefRegistry.sol";

/// @title BlobRefRegistry
contract BlobRefRegistry is IBlobRefRegistry {
    /// @dev A mapping of the hash of a blob reference to the timestamp when it was saved
    mapping(bytes32 refHash => uint256 timestamp) private _savedRefHashes;

    /// @inheritdoc IBlobRefRegistry
    function getAndSaveRefHash(uint256[] calldata blobIdxs) external returns (BlobRef memory ref, bytes32 refHash) {
        ref = _get(blobIdxs);
        refHash = _saverefHash(ref);
    }

    /// @inheritdoc IBlobRefRegistry
    function get(uint256[] calldata blobIdxs) external view returns (BlobRef memory) {
        return _get(blobIdxs);
    }

    /// @inheritdoc IBlobRefRegistry
    function isKnown(BlobRef memory ref) external view returns (bool) {
        return _savedRefHashes[keccak256(abi.encode(ref))] != 0;
    }

    /// @dev Saves the hash of a blob reference to the registry
    /// @param ref The blob reference to save
    /// @return The hash of the blob source
    function _saverefHash(BlobRef memory ref) private returns (bytes32) {
        bytes32 hash = keccak256(abi.encode(ref));
        _savedRefHashes[hash] = block.timestamp;
        return hash;
    }

    /// @dev Retrieves the blob reference for given blob indices
    /// @param blobIdxs The indices of the blobhashes to retrieve
    /// @return The blob reference constructed from the block's number and the list of blob hashes
    function _get(uint256[] calldata blobIdxs) private view returns (BlobRef memory) {
        uint256 nBlobs = blobIdxs.length;
        require(nBlobs != 0, "No blobs provided");

        bytes32[] memory blobhashes = new bytes32[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobhashes[i] = blobhash(blobIdxs[i]);
            require(blobhashes[i] != 0, "Blob not found");
        }

        return BlobRef(block.number, blobhashes);
    }
}
