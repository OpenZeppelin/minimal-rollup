// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";

contract MockCheckpointTracker is ICheckpointTracker {
    error NotImplemented();

    function getProvenCheckpoint() external pure returns (Checkpoint memory) {
        revert NotImplemented();
    }

    function proveTransition(Checkpoint calldata, Checkpoint calldata, uint256, bytes calldata)
        external
        pure
        returns (uint256)
    {
        revert NotImplemented();
    }
}
