// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {ICommitmentStore} from "./ICommitmentStore.sol";
import {IInbox} from "./IInbox.sol";
import {IVerifier} from "./IVerifier.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CheckpointTracker is ICheckpointTracker, Ownable {
    /// @dev The number of delayed publications up to the proven checkpoint
    uint256 private _totalDelayedPublications;

    /// @dev The publication id of the current proven checkpoint representing the latest verified state of the rollup
    uint256 public provenPublicationId;

    IInbox public immutable inbox;
    IVerifier public immutable verifier;
    ICommitmentStore public immutable commitmentStore;

    address public proverManager;

    /// @param _genesis the checkpoint commitment describing the initial state of the rollup
    /// @param _inbox the inbox contract that contains the publication feed
    /// @param _verifier a contract that can verify the validity of a transition from one checkpoint to another
    /// @param _commitmentStore contract responsible storing historical commitments
    constructor(bytes32 _genesis, address _inbox, address _verifier, address _commitmentStore) Ownable(msg.sender) {
        // set the genesis checkpoint commitment of the rollup - genesis is trusted to be correct
        require(_genesis != 0, ZeroGenesisCommitment());
        inbox = IInbox(_inbox);
        uint256 latestPublicationId = inbox.getNextPublicationId() - 1;

        verifier = IVerifier(_verifier);
        commitmentStore = ICommitmentStore(_commitmentStore);

        _saveCommitment(latestPublicationId, _genesis);
    }

    /// @inheritdoc ICheckpointTracker
    function updateProverManager(address _proverManager) external onlyOwner {
        proverManager = _proverManager;
        emit ProverManagerUpdated(_proverManager);
    }

    /// @inheritdoc ICheckpointTracker
    /// @dev Accepts the last proven checkpoint (or an older one) as the start checkpoint. The reason we allow for an
    /// older checkpoint is to prevent cases where a prover spends time generating a larger proof and the checkpoint
    /// changes in the mean time.
    function proveTransition(Checkpoint calldata start, Checkpoint calldata end, bytes calldata proof)
        external
        returns (uint256 numPublications, uint256 numDelayedPublications)
    {
        require(proverManager == address(0) || msg.sender == proverManager, OnlyProverManager());

        require(start.commitment != 0, ZeroStartCommitment());
        require(end.commitment != 0, ZeroEndCommitment());
        require(
            start.publicationId <= provenPublicationId,
            InvalidStartPublication(start.publicationId, provenPublicationId)
        );

        // Only count publications that have not been proven yet
        numPublications = end.publicationId - provenPublicationId;
        numDelayedPublications = end.totalDelayedPublications - _totalDelayedPublications;
        require(
            numDelayedPublications <= numPublications,
            ExcessiveDelayedPublications(numDelayedPublications, numPublications)
        );

        bytes32 startPublicationHash = inbox.getPublicationHash(start.publicationId);
        bytes32 endPublicationHash = inbox.getPublicationHash(end.publicationId);
        require(endPublicationHash != 0, EndPublicationNotFound());

        verifier.verifyProof(
            startPublicationHash,
            endPublicationHash,
            start.commitment,
            end.commitment,
            _provenCommitment(),
            numDelayedPublications,
            proof
        );

        _saveCommitment(end.publicationId, end.commitment);
        _totalDelayedPublications = end.totalDelayedPublications;
    }

    /// @dev Saves the latest commitment under the publication ID and emit an event
    /// @dev Disregard the totalDelayedPublications because it has no meaning on layer 2
    /// @param publicationId The ID of the publication to set as the latest proven checkpoint
    /// @param commitment The checkpoint commitment representing the state at the given publication ID
    function _saveCommitment(uint256 publicationId, bytes32 commitment) internal {
        provenPublicationId = publicationId;
        commitmentStore.storeCommitment(publicationId, commitment);
        emit CommitmentSaved(publicationId, commitment);
    }

    function _provenCommitment() internal view returns (bytes32) {
        return commitmentStore.commitmentAt(address(this), provenPublicationId);
    }
}
