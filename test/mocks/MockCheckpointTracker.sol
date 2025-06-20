// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";

contract MockCheckpointTracker is ICheckpointTracker {
    error NotImplemented();

    uint256 public constant LAST_PROVEN_ID = 10;
    bytes32 public constant LAST_PROVEN_COMMITMENT = keccak256("mockCheckpoint");
    uint256 public constant TOTAL_DELAYED = 2;

    // Return a hardcoded checkpoint. Different scenarios can be tested by using different
    // publications/checkpoints relative to this one.
    function getProvenCheckpoint() external pure returns (Checkpoint memory) {
        return ICheckpointTracker.Checkpoint({
            publicationId: LAST_PROVEN_ID,
            commitment: LAST_PROVEN_COMMITMENT,
            totalDelayedPublications: TOTAL_DELAYED
        });
    }

    function proveTransition(Checkpoint calldata, Checkpoint calldata, bytes calldata)
        external
        pure
        returns (uint256, uint256)
    {
        revert NotImplemented();
    }
}
