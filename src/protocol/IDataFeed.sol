// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDataFeed {
    struct Publication {
        address publisher;
        uint256 timestamp;
        bytes32[] blobHashes;
    }

    /// @notice Emitted when a new publication is created
    /// @param pubHash the hash of the new publication
    /// @param publication the Publication struct
    event Published(bytes32 indexed pubHash, Publication publication);

    /// @notice Publish data as blobs for data availability
    function publish(uint256 numBlobs) external;

    /// @notice Returns the hash of the publication at the given index
    function getPublicationHash(uint256 idx) external view returns (bytes32);
}
