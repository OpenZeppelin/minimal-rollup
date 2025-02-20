// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDataFeed {
    struct MetadataQuery {
        address provider;
        bytes input;
        uint256 value;
    }

    struct Publication {
        uint256 id;
        bytes32 prevHash;
        address publisher;
        uint256 timestamp;
        uint256 blockNumber;
        bytes32 dataHash;
        MetadataQuery[] queries;
        bytes[] metadata;
    }

    /// @notice Emitted when a new publication is created
    /// @param pubHash the hash of the new publication
    /// @param publication the Publication struct describing the preimages to pubHash
    event Published(bytes32 indexed pubHash, Publication publication);

    /// @notice Publish arbitrary data for data availability.
    /// @param numBlobs the number of blobs accompanying this function call.
    /// @param data the data to publish in calldata.
    /// @param queries the calls required to retrieve L1 metadata hashes associated with this publication.
    /// @dev there can be multiple queries because a single publication might represent multiple rollups,
    /// each with their own L1 metadata requirements
    /// @dev append a hash representing all blobs and L1 metadata to `publicationHashes`.
    /// The number of blobs is not validated. Additional blobs are ignored. Empty blobs have a hash of zero.
    function publish(uint256 numBlobs, bytes calldata data, MetadataQuery[] calldata queries) external payable;

    /// @notice retrieve a hash representing a previous publication
    /// @param idx the index of the publication hash
    /// @return _ the corresponding publication hash
    function getPublicationHash(uint256 idx) external view returns (bytes32);
}
