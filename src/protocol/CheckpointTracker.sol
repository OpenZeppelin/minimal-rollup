// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {IPublicationFeed} from "./IPublicationFeed.sol";
import {IVerifier} from "./IVerifier.sol";

contract CheckpointTracker is ICheckpointTracker {
    /// @notice The hash of the current proven checkpoint representing the latest verified state of the rollup
    /// @dev Previous checkpoints are not stored here but are synchronized to the `SignalService`
    /// @dev A checkpoint commitment is any value (typically a state root) that uniquely identifies
    /// the state of the rollup at a specific point in time
    bytes32 public provenCheckpointHash;

    /// @notice Verified transitions between two checkpoints
    /// @dev the startCheckpoint is not necessarily valid, but the endCheckpoint is correctly built on top of it.
    mapping(bytes32 startCheckpointHash => bytes32 endCheckpointHash) public transitions;

    IPublicationFeed public immutable publicationFeed;

    // This would usually be retrieved dynamically as in the current Taiko implementation, but for simplicity we are
    // just setting it in the constructor
    IVerifier public immutable verifier;

    /// @param _genesis the checkpoint commitment describing the initial state of the rollup
    /// @param _publicationFeed the input data source that updates the state of this rollup
    /// @param _verifier a contract that can verify the validity of a transition from one checkpoint to another
    constructor(bytes32 _genesis, address _publicationFeed, address _verifier) {
        // set the genesis checkpoint commitment of the rollup - genesis is trusted to be correct
        require(_genesis != 0, "genesis checkpoint commitment cannot be 0");

        publicationFeed = IPublicationFeed(_publicationFeed);
        verifier = IVerifier(_verifier);

        Checkpoint memory genesisCheckpoint = Checkpoint({publicationId: 0, commitment: _genesis});
        provenCheckpointHash = keccak256(abi.encode(genesisCheckpoint));
        emit CheckpointSeen(genesisCheckpoint.publicationId, genesisCheckpoint.commitment, provenCheckpointHash);
        emit CheckpointProven(provenCheckpointHash);
    }

    /// @inheritdoc ICheckpointTracker
    function proveTransition(Checkpoint calldata start, Checkpoint calldata end, bytes calldata proof) external {
        bytes32 startCheckpointHash = keccak256(abi.encode(start));
        bytes32 endCheckpointHash = keccak256(abi.encode(end));

        require(end.commitment != 0, "Checkpoint commitment cannot be 0");
        // TODO: once the proving incentive mechanism is in place we should reconsider this requirement because
        // ideally we would use the proof that creates the longest chain of proven publications.
        require(transitions[startCheckpointHash] == 0, "Checkpoint already has valid transition");
        require(start.publicationId < end.publicationId, "Start must be before end");
        require(end.publicationId < publicationFeed.getNextPublicationId(), "Publication does not exist");

        // Each checkpoint may emit CheckpointSeen as a start and end checkpoint
        emit CheckpointSeen(start.publicationId, start.commitment, startCheckpointHash);
        emit CheckpointSeen(end.publicationId, end.commitment, endCheckpointHash);

        verifier.verifyProof(
            publicationFeed.getPublicationHash(start.publicationId),
            publicationFeed.getPublicationHash(end.publicationId),
            start.commitment,
            end.commitment,
            proof
        );

        emit TransitionProven(startCheckpointHash, endCheckpointHash);

        if (startCheckpointHash == provenCheckpointHash) {
            while (transitions[endCheckpointHash] != 0) {
                endCheckpointHash = transitions[endCheckpointHash];
            }
            provenCheckpointHash = endCheckpointHash;
            emit CheckpointProven(endCheckpointHash);
        } else {
            transitions[startCheckpointHash] = endCheckpointHash;
        }
    }
}
