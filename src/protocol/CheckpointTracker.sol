// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {ICommitmentStore} from "./ICommitmentStore.sol";
import {IInbox} from "./IInbox.sol";
import {IVerifier} from "./IVerifier.sol";

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract CheckpointTracker is ICheckpointTracker, Ownable {
    /// @dev The number of delayed publications up to the proven checkpoint
    uint256 private _totalDelayedPublications;

    /// @dev The publication id of the current proven checkpoint representing the latest verified state of the rollup
    uint256 public provenPublicationId;

    IInbox public immutable inbox;
    IVerifier public immutable verifier;
    ICommitmentStore public immutable commitmentStore;

    address public proverManager;

    bool private _proverManagerInitialised;

    /// @dev Modifier to check if proverManager has been initialised
    modifier checkProverInitialized() {
        require(_proverManagerInitialised, "ProverManager not initialised");
        _;
    }

    /// @param _genesis the checkpoint commitment describing the initial state of the rollup
    /// @param _inbox the inbox contract that contains the publication feed
    /// @param _verifier a contract that can verify the validity of a transition from one checkpoint to another
    /// @param _commitmentStore contract responsible storing historical commitments
    /// @param _owner Owner that is allowed to set prover manager address
    constructor(bytes32 _genesis, address _inbox, address _verifier, address _commitmentStore, address _owner)
        Ownable(_owner)
    {
        // set the genesis checkpoint commitment of the rollup - genesis is trusted to be correct
        require(_genesis != 0, "genesis checkpoint commitment cannot be 0");
        inbox = IInbox(_inbox);
        uint256 latestPublicationId = inbox.getNextPublicationId() - 1;

        verifier = IVerifier(_verifier);
        commitmentStore = ICommitmentStore(_commitmentStore);

        _saveCommitment(latestPublicationId, _genesis);
    }

    /// @inheritdoc ICheckpointTracker
    /// @dev Can only be called once, allowed prover manager to be zero
    function initializeProverManager(address _proverManager) external onlyOwner {
        require(!_proverManagerInitialised, "ProverManager already initialised");
        proverManager = _proverManager;
        _proverManagerInitialised = true;
        emit ProverManagerInitialised(_proverManager);
    }

    /// @inheritdoc ICheckpointTracker
    /// @dev Accepts the last proven checkpoint (or an older one) as the start checkpoint. The reason we allow for an
    /// older checkpoint is to prevent cases where a prover spends time generating a larger proof and the checkpoint
    /// changes in the mean time.
    function proveTransition(Checkpoint calldata start, Checkpoint calldata end, bytes calldata proof)
        external
        checkProverInitialized
        returns (uint256 numPublications, uint256 numDelayedPublications)
    {
        require(
            proverManager == address(0) || msg.sender == proverManager, "Only the prover manager can call this function"
        );

        require(start.commitment != 0, "Start checkpoint commitment cannot be 0");
        require(end.commitment != 0, "End checkpoint commitment cannot be 0");
        require(start.publicationId <= provenPublicationId, "Start publication must precede latest proven checkpoint");

        // Only count publications that have not been proven yet
        numPublications = end.publicationId - provenPublicationId;
        numDelayedPublications = end.totalDelayedPublications - _totalDelayedPublications;
        require(
            numDelayedPublications <= numPublications,
            "Number of delayed publications cannot be greater than the total number of publications"
        );

        bytes32 startPublicationHash = inbox.getPublicationHash(start.publicationId);
        bytes32 endPublicationHash = inbox.getPublicationHash(end.publicationId);
        require(endPublicationHash != 0, "End publication does not exist");

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
