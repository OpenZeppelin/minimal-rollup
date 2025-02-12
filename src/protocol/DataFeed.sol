// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract DataFeed {
    bytes32[] publicationHashes;

    constructor() {
        // guarantee there is always a previous hash
        publicationHashes.push(0);
    }

    function publish(uint256 numBlobs) external {
        bytes32[] memory blobHashes = new bytes32[](numBlobs);
        for (uint256 i = 0; i < numBlobs; ++i) {
            blobHashes[i] = blobhash(i);
        }
        bytes32 prevHash = publicationHashes[publicationHashes.length - 1];
        bytes32 pubHash = keccak256(abi.encode(prevHash, msg.sender, block.timestamp, blobHashes));
        publicationHashes.push(pubHash);
    }

    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        return publicationHashes[idx];
    }
}
