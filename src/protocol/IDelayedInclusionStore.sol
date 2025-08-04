// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDelayedInclusionStore {
    struct Inclusion {
        bytes32 blobRefHash;
    }

    /// @notice Emitted when a list of delayed inclusions are processed by the inbox
    /// @param inclusionsList list of inclusions
    event DelayedInclusionProcessed(Inclusion[] inclusionsList);

    /// @dev Blob ref registry address cannot be zero
    error ZeroBlobRefRegistry();

    /// @notice Register a delayed publication for later inclusion
    /// @param blobIndices An array of blob indices to be registered where the delayed publications are included
    function publishDelayed(uint256[] memory blobIndices) external;
}
