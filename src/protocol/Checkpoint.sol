// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IPublicationFeed} from "./IPublicationFeed.sol";
import {IVerifier} from "./IVerifier.sol";

contract Checkpoint {
    /// @notice The current proven checkpoint representing the latest verified state of the rollup
    /// @dev Previous checkpoints are not stored here but are synchronized to the `SignalService`
    /// @dev A checkpoint is a cryptographic commitment (typically a state root) that uniquely identifies
    /// the state of the rollup at a specific point in time
    bytes32 public checkpoint;

    /// @notice The index of the publication associated with the current checkpoint. This value will always increase.
    uint256 public publicationId;

    IPublicationFeed public immutable _publicationFeed;

    // This would usually be retrieved dynamically as in the current Taiko implementation, but for simplicity we are
    // just setting it in the constructor
    IVerifier public immutable _verifier;

    /// @notice Emitted when a checkpoint is proven
    /// @param publicationId the index of the publication at which the checkpoint was proven
    /// @param checkpoint the checkpoint that was proven
    event CheckpointProven(uint256 indexed publicationId, bytes32 indexed checkpoint);

    /// @param genesis the checkpoint describing the initial state of the rollup
    /// @param publicationFeed the input data source that updates the state of this rollup
    /// @param verifier a contract that can verify the validity of a transition from one checkpoint to another
    constructor(bytes32 genesis, address publicationFeed, address verifier) {
        // set the genesis checkpoint of the rollup - genesis is trusted to be correct
        require(genesis != 0, "genesis checkpoint cannot be 0");
        checkpoint = genesis;
        _publicationFeed = IPublicationFeed(publicationFeed);
        _verifier = IVerifier(verifier);
    }

    /// @notice Verifies and updates the rollup state with a new checkpoint
    /// @param end The publication index of the proposed checkpoint
    /// @param newCheckpoint The proposed new checkpoint value to transition to
    /// @param proof Arbitrary data passed to the `_verifier` contract to confirm the transition validity.
    function proveTransition(uint256 end, bytes32 newCheckpoint, bytes calldata proof) external {
        require(newCheckpoint != 0, "Checkpoint cannot be 0");
        require(end > publicationId, "Publication already proven");

        IVerifier(_verifier).verifyProof(
            _publicationFeed.getPublicationHash(publicationId),
            _publicationFeed.getPublicationHash(end),
            checkpoint,
            newCheckpoint,
            proof
        );

        checkpoint = newCheckpoint;
        publicationId = end;

        emit CheckpointProven(end, checkpoint);
    }
}
