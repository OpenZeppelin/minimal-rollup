// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";

contract MockCheckpointTracker is ICheckpointTracker {
    /// @notice Do nothing. All checkpoints and proofs are accepted.
    function proveTransition(Checkpoint calldata start, Checkpoint calldata end, bytes calldata proof) external {}
}
