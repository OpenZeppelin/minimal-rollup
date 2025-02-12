// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDataFeed {
    /// @notice Publish data as blobs for data availability
    function publish(uint256 numBlobs) external;

    /// @notice Returns the hash of the publication at the given index
    function getPublicationHash(uint256 idx) external view returns (bytes32);
}
