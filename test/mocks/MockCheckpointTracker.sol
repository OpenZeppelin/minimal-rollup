// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";

contract MockCheckpointTracker is ICheckpointTracker {
    error NotImplemented();

    // Return a hardcoded value. Different scenarios can be tested by using different
    // publications/checkpoints relative to this one.
    uint256 public provenPublicationId = 10;

    function proveTransition(Checkpoint calldata, Checkpoint calldata, bytes calldata)
        external
        pure
        returns (uint256, uint256)
    {
        revert NotImplemented();
    }
}
