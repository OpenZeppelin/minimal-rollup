// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {ICommitmentStore} from "./ICommitmentStore.sol";
import {IInbox} from "./IInbox.sol";
import {IVerifier} from "./IVerifier.sol";

contract CheckpointTracker is ICheckpointTracker {
    /// @dev The publication id of the current proven checkpoint representing
    /// the latest verified state of the rollup
    uint256 private _provenPublicationId;

    IInbox public immutable inbox;
    IVerifier public immutable verifier;
    ICommitmentStore public immutable commitmentStore;
    address public immutable proverManager;

    /// @param _genesis the checkpoint commitment describing the initial state of the rollup
    /// @param _inbox the inbox contract that contains the publication feed
    /// @param _verifier a contract that can verify the validity of a transition from one checkpoint to another
    /// @param _proverManager contract responsible for managing the prover auction
    /// @param _commitmentStore contract responsible storing historical commitments
    constructor(bytes32 _genesis, address _inbox, address _verifier, address _proverManager, address _commitmentStore) {
        // set the genesis checkpoint commitment of the rollup - genesis is trusted to be correct
        require(_genesis != 0, "genesis checkpoint commitment cannot be 0");
        inbox = IInbox(_inbox);
        uint256 latestPublicationId = inbox.getNextPublicationId() - 1;

        verifier = IVerifier(_verifier);
        commitmentStore = ICommitmentStore(_commitmentStore);
        proverManager = _proverManager;

        _updateCheckpoint(latestPublicationId, _genesis);
    }

    /// @inheritdoc ICheckpointTracker
    /// @dev This function does not use the `start` checkpoint since we don't support parallel transitions.
    function proveTransition(
        Checkpoint calldata,
        Checkpoint calldata end,
        uint256 numPublications,
        uint256 numDelayedPublications,
        bytes calldata proof
    ) external {
        require(
            proverManager == address(0) || msg.sender == proverManager, "Only the prover manager can call this function"
        );

        require(end.commitment != 0, "Checkpoint commitment cannot be 0");
        require(
            numDelayedPublications <= numPublications,
            "Number of delayed publications cannot be greater than the total number of publications"
        );
        Checkpoint memory latestProvenCheckpoint = getProvenCheckpoint();
        bytes32 startPublicationHash = inbox.getPublicationHash(latestProvenCheckpoint.publicationId);
        bytes32 endPublicationHash = inbox.getPublicationHash(end.publicationId);
        require(endPublicationHash != 0, "End publication does not exist");

        verifier.verifyProof(
            startPublicationHash,
            endPublicationHash,
            latestProvenCheckpoint.commitment,
            end.commitment,
            numPublications,
            numDelayedPublications,
            proof
        );

        _updateCheckpoint(end.publicationId, end.commitment);
    }

    /// @inheritdoc ICheckpointTracker
    function getProvenCheckpoint() public view returns (Checkpoint memory provenCheckpoint) {
        provenCheckpoint.publicationId = _provenPublicationId;
        provenCheckpoint.commitment = commitmentStore.commitmentAt(address(this), provenCheckpoint.publicationId);
    }

    /// @dev Updates the proven checkpoint to a new publication ID and commitment
    /// @dev Stores the commitment in the commitment store and emits an event
    /// @param publicationId The ID of the publication to set as the latest proven checkpoint
    /// @param commitment The checkpoint commitment representing the state at the given publication ID
    function _updateCheckpoint(uint256 publicationId, bytes32 commitment) internal {
        _provenPublicationId = publicationId;
        commitmentStore.storeCommitment(publicationId, commitment);
        emit CheckpointUpdated(publicationId, commitment);
    }
}
