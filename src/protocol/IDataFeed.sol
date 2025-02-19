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
        bytes32[] blobHashes;
        MetadataQuery[] queries;
        bytes[] metadata;
    }

    struct DirectPublication {
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

    /// @notice Emitted when a new direct publication is created
    /// @param pubHash the hash of the new publication
    /// @param publication the DirectPublication struct describing the preimages to pubHash
    event DirectPublished(bytes32 indexed pubHash, DirectPublication publication);

    /// @notice Publish data as blobs for data availability
    /// @param numBlobs the number of blobs accompanying this function call.
    /// @param queries the calls required to retrieve L1 metadata hashes associated with this publication.
    function publish(uint256 numBlobs, MetadataQuery[] calldata queries) external payable;

    /// @notice Publish arbitrary data for data availability.
    /// @param data the data to publish
    /// @param queries the calls required to retrieve L1 metadata hashes associated with this publication.
    function directPublish(bytes data, MetadataQuery[] calldata queries) external payable;

    /// @notice Returns the hash of the publication at the given index
    function getPublicationHash(uint256 idx) external view returns (bytes32);

    /// @notice retrieve a hash representing a previous direct publication
    function getDirectPublicationHash(uint256 idx) external view returns (bytes32);
}
