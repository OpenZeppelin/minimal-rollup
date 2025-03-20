// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDelayedInclusionStore {
    struct Inclusion {
        bytes32 blobRefHash;
    }

    /// @notice Register a delayed publication for later inclusion
    /// @param blobIndices An array of blob indices to be registered where the delayed publications are included
    function publishDelayed(uint256[] calldata blobIndices) external;

    /// @notice Returns a list of publications that should be processed by the Inbox
    function processDueInclusions() external returns (Inclusion[] memory inclusions);
}
