// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed, MetadataQuery} from "./IDataFeed.sol";

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
    /// @dev there can be multiple queries because a single publication might represent multiple rollups,
    /// each with their own L1 metadata requirements
    /// @dev append a hash representing all blobs and L1 metadata to `publicationHashes`.
    /// The number of blobs is not validated. Additional blobs are ignored. Empty blobs have a hash of zero.
    function publish(uint256 numBlobs, MetadataQuery[] calldata queries) external payable {
        bytes32[] memory blobHashes = new bytes32[](numBlobs);
        for (uint256 i = 0; i < numBlobs; ++i) {
            blobHashes[i] = blobhash(i);
        }

        uint256 nQueries = queries.length;
        bytes[] memory metadata = new bytes[](nQueries);
        uint256 totalValue;
        for (uint256 i = 0; i < nQueries; ++i) {
            (bool success, bytes memory returnData) =
                queries[i].provider.call{value: queries[i].value}(queries[i].input);
            require(success, "Metadata query failed");
            metadata[i] = returnData;
            totalValue += queries[i].value;
        }
        require(msg.value >= totalValue, "Insufficient ETH passed with publication");

        bytes32 prevHash = publicationHashes[publicationHashes.length - 1];
        bytes32 pubHash = keccak256(abi.encode(prevHash, blobHashes, queries, metadata));
        publicationHashes.push(pubHash);

        emit Publication(pubHash, queries, metadata);
    }

    /// @notice retrieve a hash representing a previous publication
    /// @param idx the index of the publication hash
    /// @return _ the corresponding publication hash
    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        return publicationHashes[idx];
    }
}
