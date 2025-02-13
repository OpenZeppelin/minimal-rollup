// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDataFeed {
    /// @notice Emitted when a new publication is created
    /// @param pubHash the hash of the new publication
    event Publication(bytes32 indexed pubHash);

    /// @notice Publish data as blobs for data availability
    function publish(uint256 numBlobs) external;

    /// @notice Returns the hash of the publication at the given index
    function getPublicationHash(uint256 idx) external view returns (bytes32);
}
