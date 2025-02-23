// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IPublicationFeed} from "./IPublicationFeed.sol";
import {IVerifier} from "./IVerifier.sol";

struct Checkpoint {
    uint256 publicationId;
    bytes32 commitment;
}

contract CheckpointTracker {

    /// @notice The current proven checkpoint representing the latest verified state of the rollup
    /// @dev Previous checkpoints are not stored here but are synchronized to the `SignalService`
    /// @dev A checkpoint commitment is any value (typically a state root) that uniquely identifies
    /// the state of the rollup at a specific point in time
    Checkpoint public checkpoint;

    IPublicationFeed public immutable _publicationFeed;

    // This would usually be retrieved dynamically as in the current Taiko implementation, but for simplicity we are
    // just setting it in the constructor
    IVerifier public immutable _verifier;

    /// @notice Emitted when a checkpoint is proven
    /// @param publicationId the index of the publication at which the commitment was proven
    /// @param commitment the checkpoint commitment that was proven
    event CheckpointProven(uint256 indexed publicationId, bytes32 indexed commitment);

    /// @param genesis the checkpoint commitment describing the initial state of the rollup
    /// @param publicationFeed the input data source that updates the state of this rollup
    /// @param verifier a contract that can verify the validity of a transition from one checkpoint to another
    constructor(bytes32 genesis, address publicationFeed, address verifier) {
        // set the genesis checkpoint commitment of the rollup - genesis is trusted to be correct
        require(genesis != 0, "genesis checkpoint commitment cannot be 0");
        checkpoint.commitment = genesis;
        _publicationFeed = IPublicationFeed(publicationFeed);
        _verifier = IVerifier(verifier);
    }

    /// @notice Verifies and updates the rollup state with a new checkpoint
    /// @param newCheckpoint The proposed new checkpoint value to transition to
    /// @param proof Arbitrary data passed to the `_verifier` contract to confirm the transition validity.
    function proveTransition(Checkpoint calldata newCheckpoint, bytes calldata proof) external {
        require(newCheckpoint.commitment != 0, "Commitment cannot be 0");
        require(newCheckpoint.publicationId > checkpoint.publicationId, "Publication already proven");

        IVerifier(_verifier).verifyProof(
            _publicationFeed.getPublicationHash(checkpoint.publicationId),
            _publicationFeed.getPublicationHash(newCheckpoint.publicationId),
            checkpoint.commitment,
            newCheckpoint.commitment,
            proof
        );

        checkpoint = newCheckpoint;

        emit CheckpointProven(newCheckpoint.publicationId, newCheckpoint.commitment);
    }
}
