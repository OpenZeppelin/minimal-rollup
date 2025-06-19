// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";

contract MockCheckpointTracker is ICheckpointTracker {
    error NotImplemented();

    uint256 public constant LAST_PROVEN_ID = 10;
    bytes32 public constant LAST_PROVEN_COMMITMENT = keccak256("mockCheckpoint");

    // Return a hardcoded checkpoint. Different scenarios can be tested by using different
    // publications/checkpoints relative to this one.
    function getProvenCheckpoint() external pure returns (Checkpoint memory) {
        return Checkpoint({publicationId: LAST_PROVEN_ID, commitment: LAST_PROVEN_COMMITMENT});
    }

    function proveTransition(Checkpoint calldata, Checkpoint calldata, uint256, bytes calldata)
        external
        pure
        returns (uint256)
    {
        revert NotImplemented();
    }
}
