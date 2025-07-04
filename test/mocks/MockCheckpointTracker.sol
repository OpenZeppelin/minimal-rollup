// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";
import {ICommitmentStore} from "src/protocol/ICommitmentStore.sol";

contract MockCheckpointTracker is ICheckpointTracker {
    Checkpoint private provenCheckpoint;
    ICommitmentStore public immutable commitmentStore;

    constructor(address _commitmentStore) {
        // Set the initial proven hash to the zero checkpoint
        Checkpoint memory zeroCheckpoint = Checkpoint({publicationId: 0, commitment: bytes32(0)});
        provenCheckpoint = zeroCheckpoint;
        commitmentStore = ICommitmentStore(_commitmentStore);
    }

    /// @notice Do nothing. All checkpoints and proofs are accepted.
    function proveTransition(
        Checkpoint calldata start,
        Checkpoint calldata end,
        uint256 numDelayedPublications,
        bytes calldata
    ) external returns (uint256) {
        commitmentStore.storeCommitment(end.publicationId, end.commitment);

        // Just return the total number of publications passed
        uint256 numPublications = end.publicationId - start.publicationId;
        require(
            numDelayedPublications <= numPublications,
            "Number of delayed publications cannot be greater than the total number of publications"
        );
        return end.publicationId - provenCheckpoint.publicationId;
    }

    /// @notice Helper to set the proven hash for easier testing
    /// @param checkpoint the checkpoint to set as proven, that will be hashed and stored as the proven hash
    function setProvenHash(Checkpoint memory checkpoint) external {
        provenCheckpoint = checkpoint;
    }

    function getProvenCheckpoint() external view returns (Checkpoint memory) {
        return provenCheckpoint;
    }
}
