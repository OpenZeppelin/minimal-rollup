// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {IPublicationFeed} from "./IPublicationFeed.sol";
import {IVerifier} from "./IVerifier.sol";

contract CheckpointTracker is ICheckpointTracker {
    /// @notice The current proven checkpoint representing the latest verified state of the rollup
    /// @dev Previous checkpoints are not stored here but are synchronized to the `SignalService`
    /// @dev A checkpoint commitment is any value (typically a state root) that uniquely identifies
    /// the state of the rollup at a specific point in time
    Checkpoint private provenCheckpoint;

    IPublicationFeed public immutable publicationFeed;
    // This would usually be retrieved dynamically as in the current Taiko implementation, but for simplicity we are
    // just setting it in the constructor
    IVerifier public immutable verifier;
    address public proverManager;

    /// @param _genesis the checkpoint commitment describing the initial state of the rollup
    /// @param _publicationFeed the input data source that updates the state of this rollup
    /// @param _verifier a contract that can verify the validity of a transition from one checkpoint to another
    /// @param _proverManager contract responsible for managing the prover auction
    constructor(bytes32 _genesis, address _publicationFeed, address _verifier, address _proverManager) {
        // set the genesis checkpoint commitment of the rollup - genesis is trusted to be correct
        require(_genesis != 0, "genesis checkpoint commitment cannot be 0");

        publicationFeed = IPublicationFeed(_publicationFeed);
        verifier = IVerifier(_verifier);
        proverManager = _proverManager;
        Checkpoint memory genesisCheckpoint = Checkpoint({publicationId: 0, commitment: _genesis});
        provenCheckpoint = genesisCheckpoint;
        emit CheckpointUpdated(genesisCheckpoint.publicationId, genesisCheckpoint.commitment);
    }

    /// @inheritdoc ICheckpointTracker
    function proveTransition(
        Checkpoint calldata start,
        Checkpoint calldata end,
        uint256 numPublications,
        bytes calldata proof
    ) external {
        require(
            proverManager == address(0) || msg.sender == proverManager, "Only the prover manager can call this function"
        );

        require(end.commitment != 0, "Checkpoint commitment cannot be 0");

        require(
            start.publicationId == provenCheckpoint.publicationId && start.commitment == provenCheckpoint.commitment,
            "Start checkpoint must be the latest proven checkpoint"
        );

        require(start.publicationId < end.publicationId, "End publication must be after the last proven publication");

        bytes32 startPublicationHash = publicationFeed.getPublicationHash(start.publicationId);
        bytes32 endPublicationHash = publicationFeed.getPublicationHash(end.publicationId);
        require(endPublicationHash != 0, "End publication does not exist");

        verifier.verifyProof(
            startPublicationHash, endPublicationHash, start.commitment, end.commitment, numPublications, proof
        );

        provenCheckpoint = end;
        emit TransitionProven(start, end);
    }

    function getProvenCheckpoint() external view returns (Checkpoint memory) {
        return provenCheckpoint;
    }
}
