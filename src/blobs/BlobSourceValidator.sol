// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IBlobSourceProvider {
    struct BlobSource {
        uint256 blockNumber;
        bytes32[] blobs;
    }

    event BlobSourceHashSaved(bytes32 indexed hash, BlobSource blobSource);
}

contract BlobSourceProvider is IBlobSourceProvider {
    mapping(bytes32 sourceHash => uint256 timestamp) private _validHashes;

    function get(uint256 numBlobs) public view returns (BlobSource memory) {
        uint256 nBlobs = numBlobs;
        uint256[] memory ids = new uint256[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            ids[i] = i;
        }
        return _get(ids);
    }

    function getAndSaveHash(uint256 numBlobs) external returns (BlobSource memory blobSource, bytes32 hash) {
        blobSource = get(numBlobs);
        hash = _saveHash(blobSource);
    }

    function isHashValid(bytes32 hash) external view returns (bool) {
        return _validHashes[hash] != 0;
    }

    function _get(uint256[] memory blobIds) private view returns (BlobSource memory) {
        uint256 nBlobs = blobIds.length;
        bytes32[] memory blobs = new bytes32[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobs[i] = blobhash(blobIds[i]);
            require(blobs[i] != 0, "Blob not found");
        }
        return BlobSource({blockNumber: block.number, blobs: blobs});
    }

    function _saveHash(BlobSource memory blobSource) private returns (bytes32 hash) {
        hash = keccak256(abi.encode(blobSource));
        _validHashes[hash] = block.timestamp;
        emit BlobSourceHashSaved(hash, blobSource);
    }
}
