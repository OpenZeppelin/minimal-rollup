// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// TODO(daniel): document this interface
interface IBlobSourceProvider {
    struct BlobSource {
        uint256 blockNumber;
        bytes32[] blobs;
    }

    event BlobSourceHashSaved(bytes32 indexed hash);

    function getAndSaveHash(uint16[] calldata blobIdxs) external returns (BlobSource memory blobSource, bytes32 hash);
    function get(uint16[] calldata blobIdxs) external view returns (BlobSource memory);
    function isKnown(BlobSource memory blobSource) external view returns (bool);
}
