// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDelayedInclusionStore {
    // TODO: should we use different types for stored inclusion and what we return to the inbox? i.e the inbox does not
    // need the due timestamp
    struct Inclusion {
        bytes32 blobRefHash;
        uint256 due;
    }

    /// @notice Returns a list of publications that should be processed by the Inbox
    function processDueInclusions() external returns (Inclusion[] memory inclusions);
}
