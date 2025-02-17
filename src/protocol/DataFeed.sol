// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed, MetadataQuery} from "./IDataFeed.sol";
import {IL1MetadataProvider} from "./IL1MetadataProvider.sol";


contract DataFeed is IDataFeed {
    /// @dev a list of hashes identifying all data accompanying calls to the `publish` function.
    bytes32[] publicationHashes;

    constructor() {
        // guarantee there is always a previous hash
        publicationHashes.push(0);
    }

    /// @notice Publish arbitrary data in blobs for data availability.
    /// @param numBlobs the number of blobs accompanying this function call.
    /// @param queries the calls required to retrieve L1 metadata hashes associated with this publication.
    /// @dev append a hash representing all blobs and L1 metadata to `publicationHashes`.
    /// The number of blobs is not validated. Additional blobs are ignored. Empty blobs have a hash of zero.
    function publish(uint256 numBlobs, MetadataQuery[] calldata queries) external {
        bytes32[] memory blobHashes = new bytes32[](numBlobs);
        for (uint256 i = 0; i < numBlobs; ++i) {
            blobHashes[i] = blobhash(i);
        }

        uint256 nQueries = queries.length;
        bytes32[] memory metadataHashes = new bytes32[](nQueries);
        for (uint256 i = 0; i < nQueries; ++i) {
            metadataHashes[i] = IL1MetadataProvider(queries[i].provider).getL1MetadataHash(queries[i].input);
        } 

        bytes32 prevHash = publicationHashes[publicationHashes.length - 1];
        bytes32 pubHash = keccak256(abi.encode(prevHash, blobHashes, metadataHashes));
        publicationHashes.push(pubHash);

        emit Publication(pubHash);
    }

    /// @notice retrieve a hash representing a previous publication
    /// @param idx the index of the publication hash
    /// @return _ the corresponding publication hash
    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        return publicationHashes[idx];
    }
}
