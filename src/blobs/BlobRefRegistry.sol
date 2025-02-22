// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IBlobRefRegistry.sol";

/// @title BlobRefRegistry
contract BlobRefRegistry is IBlobRefRegistry {
    /// @dev A mapping of the hash of a blob ref to the timestamp when it was saved
    mapping(bytes32 refHash => uint256 timestamp) private _savedRefHashes;

    /// @inheritdoc IBlobRefRegistry
    function getRefAndSaveHash(bytes32 blobIndices) external returns (BlobRef memory ref, bytes32 refHash) {
        ref = _getRef(blobIndices);
        refHash = _saveRefHash(ref);
    }

    /// @inheritdoc IBlobRefRegistry
    function getRef(bytes32 blobIndices) external view returns (BlobRef memory) {
        return _getRef(blobIndices);
    }

    /// @inheritdoc IBlobRefRegistry
    function isRefKnown(BlobRef memory ref) external view returns (bool) {
        return _savedRefHashes[keccak256(abi.encode(ref))] != 0;
    }

    /// @dev Saves the hash of a blob ref to the registry
    /// @param ref The blob ref whose hash to save
    /// @return The hash of the blob source
    function _saveRefHash(BlobRef memory ref) private returns (bytes32) {
        bytes32 hash = keccak256(abi.encode(ref));
        _savedRefHashes[hash] = block.timestamp;
        return hash;
    }

    /// @dev Retrieves the blob ref for given blob indices
    /// @param blobIndices A bytes32 value encoding up to 16 blob indices as uint16 values. The right-most uint16
    /// represents the first blob index. Indices are processed from right to left, stopping at the first 0 index
    /// encountered (excluding the right-most index).
    /// @return The blob ref constructed from the block's number and the list of blob hashes
    function _getRef(bytes32 blobIndices) private view returns (BlobRef memory) {
        uint256 nBlobs = blobIndices.length;
        require(nBlobs != 0, "No blobs provided");

        bytes32[] memory blobhashes = new bytes32[](16);

        uint256 i;
        for (; i < 16; ++i) {
            uint256 idx = uint16(uint256(blobIndices >> (16 * i)));
            if (i != 0 && idx == 0) break;
            blobhashes[i] = blobhash(idx);
            require(blobhashes[i] != 0, "Blob not found");
        }

        // resize blobhashes
        assembly {
            mstore(blobhashes, i)
        }

        return BlobRef(block.number, blobhashes);
    }
}
