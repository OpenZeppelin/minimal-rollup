// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";

interface IDelayedInclusionStore {
    function processDelayedInclusionByDeadline(uint256 deadline)
        external
        returns (IBlobRefRegistry.BlobRef[] memory blobRefs);
}
