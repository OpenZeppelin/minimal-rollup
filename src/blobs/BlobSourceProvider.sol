// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IBlobSourceProvider.sol";

/// @title BlobSourceProvider
contract BlobSourceProvider is IBlobSourceProvider {
    mapping(bytes32 sourceHash => uint256 timestamp) private _savedHashes;

    /// @inheritdoc IBlobSourceProvider
    function getAndSaveHash(uint16[] calldata blobIdxs) external returns (BlobSource memory blobSource, bytes32 hash) {
        blobSource = _get(blobIdxs);
        hash = _saveHash(blobSource);
    }

    /// @inheritdoc IBlobSourceProvider
    function get(uint16[] calldata blobIdxs) external view returns (BlobSource memory) {
        return _get(blobIdxs);
    }

    /// @inheritdoc IBlobSourceProvider
    function isValid(BlobSource memory blobSource) external view returns (bool) {
        return _savedHashes[keccak256(abi.encode(blobSource))] != 0;
    }

    function _saveHash(BlobSource memory blobSource) private returns (bytes32 hash) {
        hash = keccak256(abi.encode(blobSource));
        _savedHashes[hash] = block.timestamp;
        emit BlobSourceHashSaved(hash);
    }

    function _get(uint16[] calldata blobIdxs) private view returns (BlobSource memory) {
        uint256 nBlobs = blobIdxs.length;
        require(nBlobs != 0, "No blobs provided");

        bytes32[] memory blobs = new bytes32[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobs[i] = blobhash(blobIdxs[i]);
            require(blobs[i] != 0, "Blob not found");
        }
        return BlobSource(block.number, blobs);
    }
}
