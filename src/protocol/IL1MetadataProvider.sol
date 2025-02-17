// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IL1MetadataProvider {
    /// @notice Retrieves and hashes L1 metadata associated with a publication
    /// @param input arbitrary data required to identify the L1 metadata
    /// @return _ the hash of the metadata.
    function getL1MetadataHash(bytes calldata input) external returns (bytes32);
}
