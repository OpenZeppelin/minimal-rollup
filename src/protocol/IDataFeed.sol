// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

struct MetadataQuery {
    address provider;
    bytes input;
}

interface IDataFeed {
    /// @notice Emitted when a new publication is created
    /// @param pubHash the hash of the new publication
    event Publication(bytes32 indexed pubHash);

    /// @notice Publish data as blobs for data availability
    /// @param numBlobs the number of blobs accompanying this function call.
    /// @param queries the calls required to retrieve L1 metadata hashes associated with this publication.
    function publish(uint256 numBlobs, MetadataQuery[] calldata queries) external;

    /// @notice Returns the hash of the publication at the given index
    function getPublicationHash(uint256 idx) external view returns (bytes32);
}
