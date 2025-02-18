// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IMetadataProvider {
    /// @notice Returns the block hash corresponding to the provided anchorBlockId
    /// @param publisher The address of the publisher
    /// @param input The input to the metadata provider
    /// @return metadata The metadata
    function getMetadata(address publisher, bytes memory input) external payable returns (bytes memory metadata);
}
