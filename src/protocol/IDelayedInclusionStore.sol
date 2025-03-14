// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDelayedInclusionStore {
    struct Inclusion {
        bytes32 blobRefHash;
        uint256 timestamp;
    }

    /// @notice Returns a list of publications that should be processed by the Inbox
    function processDueInclusions() external returns (Inclusion[] memory inclusions);
}
