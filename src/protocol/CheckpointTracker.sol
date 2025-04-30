// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {ICommitmentStore} from "./ICommitmentStore.sol";
import {IPublicationFeed} from "./IPublicationFeed.sol";
import {IVerifier} from "./IVerifier.sol";

contract CheckpointTracker is ICheckpointTracker {
    /// @notice The publication id of the current proven checkpoint representing the latest verified state of the rollup
    /// @dev A checkpoint commitment is any value (typically a state root) that uniquely identifies
    /// the state of the rollup at a specific point in time
    uint256 _provenPublicationId;

    IPublicationFeed public immutable publicationFeed;
    IVerifier public immutable verifier;
    ICommitmentStore public immutable commitmentStore;
    address public proverManager;

    /// @param _genesis the checkpoint commitment describing the initial state of the rollup
    /// @param _publicationFeed the input data source that updates the state of this rollup
    /// @param _verifier a contract that can verify the validity of a transition from one checkpoint to another
    /// @param _proverManager contract responsible for managing the prover auction
    /// @param _commitmentStore contract responsible storing historical commitments
    constructor(
        bytes32 _genesis,
        address _publicationFeed,
        address _verifier,
        address _proverManager,
        address _commitmentStore
    ) {
        publicationFeed = IPublicationFeed(_publicationFeed);
        if (_genesis != 0) {
            uint256 latestPublicationId = publicationFeed.getNextPublicationId() - 1;
            require(
                _genesis == publicationFeed.getPublicationHash(latestPublicationId),
                GenesisNotLatestPublication(latestPublicationId)
            );
            _updateCheckpoint(latestPublicationId, _genesis);
        } else {
            _updateCheckpoint(0, _genesis);
        }

        verifier = IVerifier(_verifier);
        commitmentStore = ICommitmentStore(_commitmentStore);
        proverManager = _proverManager;
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

        Checkpoint memory provenCheckpoint = getProvenCheckpoint();
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

        _updateCheckpoint(end.publicationId, end.commitment);
    }

    function getProvenCheckpoint() public view returns (Checkpoint memory provenCheckpoint) {
        provenCheckpoint.publicationId = _provenPublicationId;
        provenCheckpoint.commitment = commitmentStore.commitmentAt(address(this), provenCheckpoint.publicationId);
    }

    function _updateCheckpoint(uint256 publicationId, bytes32 commitment) internal {
        _provenPublicationId = publicationId;
        commitmentStore.storeCommitment(publicationId, commitment);
        emit CheckpointUpdated(publicationId, commitment);
    }
}
