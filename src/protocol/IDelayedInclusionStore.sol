// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDelayedInclusionStore {
    struct Inclusion {
        bytes32 blobRefHash;
    }

    function processDueInclusions() external returns (Inclusion[] memory inclusions);
}
