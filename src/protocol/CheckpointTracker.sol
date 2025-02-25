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
    Checkpoint public latestCheckpoint;
    bytes32 public latestCheckpointHash;

    /// @notice Verified transitions between two checkpoints
    /// @dev the start checkpoint is not necessarily valid, but the end checkpoint is correctly built on top of it.
    mapping(bytes32 startCheckpointHash => Checkpoint endCheckpoint) public transitions;

    IPublicationFeed public immutable publicationFeed;

    // This would usually be retrieved dynamically as in the current Taiko implementation, but for simplicity we are
    // just setting it in the constructor
    IVerifier public immutable verifier;

    /// @notice The maximum number of additional checkpoint transitions to apply in a single proof
    /// @dev This limits the overhead required to submit a proof
    uint256 private constant MAX_EXTRA_UPDATES = 10; // TODO: What is a reasonable number here?

    /// @param _genesisComittment the commitment describing the initial state of the rollup
    /// @param _publicationFeed the input data source that updates the state of this rollup
    /// @param _verifier a contract that can verify the validity of a transition from one checkpoint to another
    constructor(bytes memory _genesisComittment, address _publicationFeed, address _verifier) {
        publicationFeed = IPublicationFeed(_publicationFeed);
        verifier = IVerifier(_verifier);

        uint256 genesisPublicationId = 0;
        bytes32 genesisCommitmentHash = keccak256(_genesisComittment);
        latestCheckpointHash = keccak256(abi.encodePacked(genesisPublicationId, genesisCommitmentHash));

        Checkpoint memory genesisCheckpoint = Checkpoint(genesisPublicationId, _genesisComittment);
        latestCheckpoint = genesisCheckpoint;

        emit CheckpointUpdated(genesisCommitmentHash, genesisCheckpoint);
    }

    function proveTransition(
        uint256 startPublicationId,
        uint256 startCommitmentHash,
        Checkpoint calldata endCheckpoint,
        bytes calldata proof
    ) external {
        require(endCheckpoint.commitment.length != 0, "Checkpoint commitment cannot be empty");
        bytes32 startChekpointHash = keccak256(abi.encodePacked(startPublicationId, startCommitmentHash));

        // TODO: once the proving incentive mechanism is in place we should reconsider this requirement because
        // ideally we would use the proof that creates the longest chain of proven publications.
        require(transitions[startChekpointHash].publicationId == 0, "Checkpoint already has valid transition");
        require(startPublicationId < endCheckpoint.publicationId, "Start must be before end");

        bytes32 startPublicationHash = publicationFeed.getPublicationHash(startPublicationId);
        bytes32 endPublicationHash = publicationFeed.getPublicationHash(endCheckpoint.publicationId);
        require(endPublicationHash != 0, "Publication does not exist");

        verifier.verifyProof(
            startPublicationHash, endPublicationHash, endPublicationHash, keccak256(endCheckpoint.commitment), proof
        );

        // TODO: in some cases, this endcheckpoint don't need to be saved, but lets do it in the future after ABI are
        // finalized.
        transitions[startChekpointHash] = endCheckpoint;
        emit TransitionProven(startPublicationId, startCommitmentHash, endCheckpoint);

        _updateLatestCheckpoint();
    }

    /// @dev To limit the overhead, we cannot require a proof to find the last proven checkpoint
    /// Instead, each proof should advance the checkpoint by a manageable increment, regardless
    /// of which transition it proves.
    function _updateLatestCheckpoint() internal {
        bytes32 _latestCheckpointHash = latestCheckpointHash;
        Checkpoint memory _latestCheckpoint;

        for (uint256 i; i < MAX_EXTRA_UPDATES; ++i) {
            _latestCheckpoint = transitions[_latestCheckpointHash];
            if (_latestCheckpoint.publicationId == 0) break;
        }

        if (_latestCheckpointHash != latestCheckpointHash) {
            latestCheckpointHash = _latestCheckpointHash;
            latestCheckpoint = _latestCheckpoint;
            emit CheckpointUpdated(_latestCheckpointHash, _latestCheckpoint);

            // TODO: save latestCheckpoint to signal service?
        }
    }
}
