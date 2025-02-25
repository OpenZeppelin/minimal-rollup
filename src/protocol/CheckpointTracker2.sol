// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {IPublicationFeed} from "./IPublicationFeed.sol";
import {IVerifier} from "./IVerifier.sol";

contract CheckpointTracker2 {
    struct Checkpoint {
        uint64 publicationId;
        uint64 blockNumber;
        bytes32 blockHash;
    }

    event CheckpointProven(Checkpoint checkpoint);

    event TransitionProven(bytes32 parentHash, Checkpoint end);

    bytes32 public provenParentHash;
    mapping(bytes32 parentHash => Checkpoint endCheckpoint) public transitions;

    function proveTransition(Checkpoint calldata parent, Checkpoint calldata checkpoint, bytes calldata proof)
        external
    {
        require(checkpoint.publicationId != 0, "End publication id cannot be 0");
        require(checkpoint.blockNumber != 0, "End block number cannot be 0");
        require(checkpoint.blockHash != 0, "End block hash cannot be 0");

        require(
            checkpoint.publicationId > parent.publicationId,
            "End publication id must be greater than parent publication id"
        );
        require(
            checkpoint.blockNumber > parent.blockNumber, "End block number must be greater than parent block number"
        );

        bytes32 parentHash = keccak256(abi.encode(parent));

        require(transitions[parentHash].publicationId == 0, "transition already proven");

        // Verify the proof below

        // If the proof is valid, set the end checkpoint
        transitions[parentHash] = checkpoint; // TODO: sometimes we do not need to save this transition
        emit TransitionProven(parentHash, checkpoint);

        bytes32 _provenParentHash = provenParentHash;
        Checkpoint memory _checkpoint = transitions[_provenParentHash];

        while (true) {
            bytes32 checkpointHash = keccak256(abi.encode(checkpoint));

            _checkpoint = transitions[checkpointHash];
            if (checkpoint.publicationId != 0) {
                _provenParentHash = checkpointHash;
            } else {
                break;
            }
        }

        if (provenParentHash == _provenParentHash) {
            provenParentHash = _provenParentHash;
            // IStateSyncer.syncState(_checkpoint.blockNumber, _checkpoint.blockHash);
            emit CheckpointProven(_checkpoint);
        }
    }
}
