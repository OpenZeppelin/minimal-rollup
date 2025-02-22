// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDelayedInclusionStore {
    struct Inclusion {
        bytes32 blobRefHash;
    }

    function processDelayedInclusionByDeadline(uint256 deadline) external returns (Inclusion[] memory inclusions);
}
