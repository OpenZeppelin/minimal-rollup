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
    bytes32 public provenHash;

    /// @notice Verified transitions between two checkpoints
    /// @dev the start checkpoint is not necessarily valid, but the end checkpoint is correctly built on top of it.
    mapping(bytes32 startHash => bytes32 endHash) public transitions;

    IPublicationFeed public immutable publicationFeed;

    // This would usually be retrieved dynamically as in the current Taiko implementation, but for simplicity we are
    // just setting it in the constructor
    IVerifier public immutable verifier;

    /// @notice The maximum number of additional checkpoint transitions to apply in a single proof
    /// @dev This limits the overhead required to submit a proof
    uint256 constant MAX_EXTRA_UPDATES = 10; // TODO: What is a reasonable number here?

    /// @param _genesis the checkpoint commitment describing the initial state of the rollup
    /// @param _publicationFeed the input data source that updates the state of this rollup
    /// @param _verifier a contract that can verify the validity of a transition from one checkpoint to another
    constructor(bytes32 _genesis, address _publicationFeed, address _verifier) {
        // set the genesis checkpoint commitment of the rollup - genesis is trusted to be correct
        require(_genesis != 0, "genesis checkpoint commitment cannot be 0");

        publicationFeed = IPublicationFeed(_publicationFeed);
        verifier = IVerifier(_verifier);

        Checkpoint memory genesisCheckpoint = Checkpoint({publicationId: 0, commitment: _genesis});
        provenHash = keccak256(abi.encode(genesisCheckpoint));
        emit CheckpointUpdated(provenHash);
    }

    /// @inheritdoc ICheckpointTracker
    function proveTransition(Checkpoint calldata start, Checkpoint calldata end, bytes calldata proof) external {
        bytes32 startHash = keccak256(abi.encode(start));
        bytes32 endHash = keccak256(abi.encode(end));
        bytes32 endPublicationId = publicationFeed.getPublicationHash(end.publicationId);

        require(end.commitment != 0, "Checkpoint commitment cannot be 0");
        // TODO: once the proving incentive mechanism is in place we should reconsider this requirement because
        // ideally we would use the proof that creates the longest chain of proven publications.
        require(transitions[startHash] == 0, "Checkpoint already has valid transition");
        require(start.publicationId < end.publicationId, "Start must be before end");
        require(endPublicationId != 0, "Publication does not exist");

        verifier.verifyProof(
            publicationFeed.getPublicationHash(start.publicationId),
            endPublicationId,
            start.commitment,
            end.commitment,
            proof
        );

        emit TransitionProven(start, end);

        if (startHash == provenHash) {
            provenHash = endHash;
            emit CheckpointUpdated(endHash);
        } else {
            transitions[startHash] = endHash;
        }

        _updateProvenHash();
    }

    /// @dev To limit the overhead, we cannot require a proof to find the last proven checkpoint
    /// Instead, each proof should advance the checkpoint by a manageable increment, regardless
    /// of which transition it proves.
    function _updateProvenHash() internal {
        bytes32 newProvenHash = transitions[provenHash];
        if (newProvenHash == 0) {
            return;
        }
        // Use another variable to avoid extra storage loads
        bytes32 nextRecord = newProvenHash;
        for (uint256 i; i < MAX_EXTRA_UPDATES && nextRecord != 0; ++i) {
            newProvenHash = nextRecord;
            nextRecord = transitions[nextRecord];
        }
        provenHash = newProvenHash;
        emit CheckpointUpdated(newProvenHash);
    }
}
