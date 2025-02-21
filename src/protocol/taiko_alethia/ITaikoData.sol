// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ITaikoData {
    /// @dev Represents a data source for a proposal, containing multiple blobs.
    /// These blobs are concatenated into a single blob or string, which then is decoded into a specific format as
    /// defined by the node or client.
    struct DataSource {
        bytes32[] blobs;
    }

    /// @dev Represents a proposal, which includes an anchor block hash and an array of data sources.
    /// The anchor block hash may be set to 0, indicating that the anchor transaction should use 0 as the anchor block
    /// identifier.
    /// Each data source is decoded into a data object, and these objects are concatenated into a list. This list is
    /// then used to derive Taiko blocks.
    struct Proposal {
        bytes32 anchorBlockhash;
        DataSource[] proposalDataList;
    }
}
