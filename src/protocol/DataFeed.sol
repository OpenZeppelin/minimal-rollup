// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";

contract DataFeed is IDataFeed {
    /// @dev a list of hashes identifying all data accompanying calls to the `publish` function.
    bytes32[] public publicationHashes;

    constructor() {
        // guarantee there is always a previous hash
        publicationHashes.push(0);
    }

    /// @notice Publish arbitrary data in blobs for data availability.
    /// @param numBlobs the number of blobs accompanying this function call.
    /// @dev append a hash representing all blobs and L1 contextual information to `publicationHashes`.
    /// The number of blobs is not validated. Additional blobs are ignored. Empty blobs have a hash of zero.
    function publish(uint256 numBlobs) external {
        require(numBlobs > 0, "no data to publish");

        Publication memory publication = Publication(msg.sender, block.timestamp, new bytes32[](numBlobs));

        for (uint256 i; i < numBlobs; ++i) {
            publication.blobHashes[i] = _getBlobhash(i);
        }

        bytes32 prevHash = publicationHashes[publicationHashes.length - 1];
        bytes32 pubHash = keccak256(abi.encode(prevHash, publication));
        publicationHashes.push(pubHash);

        emit Published(pubHash, publication);
    }

    /// @notice retrieve a hash representing a previous publication
    /// @param idx the index of the publication hash
    /// @return _ the corresponding publication hash
    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        return publicationHashes[idx];
    }

    /// @notice retrieve a hash representing a previous publication
    /// @dev This function can be overridden by tests for easier testing
    /// @param idx the index of the publication hash
    /// @return _ the corresponding publication hash
    function _getBlobhash(uint256 idx) internal view virtual returns (bytes32) {
        return blobhash(idx);
    }
}
