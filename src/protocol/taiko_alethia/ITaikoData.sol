// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";

interface ITaikoData {
    /// @dev Represents a data source for a proposal, containing multiple blobs.
    /// These blobs are concatenated into a single blob or string, which then is decoded into a specific format as
    /// defined by the node or client.
    struct DataSource {
        IBlobRefRegistry.BlobRef blobRef;
    }
}
