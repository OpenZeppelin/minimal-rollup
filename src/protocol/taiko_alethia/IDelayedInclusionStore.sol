// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDelayedInclusionStore {
    function processDelayedInclusionByDeadline(uint256 deadline) external returns (bytes32[][] memory blobGroups);
}
