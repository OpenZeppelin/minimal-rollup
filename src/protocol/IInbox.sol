// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IInbox {
    function publish(uint256 nBlobs, uint64 anchorBlockId) external;
}
