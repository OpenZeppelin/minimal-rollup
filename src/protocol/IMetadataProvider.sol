// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";

interface IMetadataProvider {
    /// @notice Returns L1 metadata associated with a publication
    /// @param publisher The address of the publisher
    /// @param input The input to the metadata provider
    /// @return metadata The metadata
    function getMetadata(address publisher, bytes memory input) external payable returns (bytes memory metadata);

    /// @notice Returns the hash of the latest available direct publication
    /// @return directPublicationHash The hash of the latest direct publication
    function getDirectPublicationHash() external view returns (bytes32);

    /// @notice Updates the hash of the latest available direct publication for the rollup
    /// @param publication The direct publication
    /// @param idx The index of the direct publication in the `DataFeed` contract
    function setLastDirectPublicationHash(IDataFeed.DirectPublication calldata publication, uint256 idx) external;
}
