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

    event TransitionProven(bytes32 startHash, Checkpoint end);

    bytes32 public lastStartHash;
    mapping(bytes32 startHash => Checkpoint endCheckpoint) public transitions;

    function proveTransition(Checkpoint calldata start, Checkpoint calldata end, bytes calldata proof) external {
        require(end.publicationId != 0, "End publication id cannot be 0");
        require(end.blockNumber != 0, "End block number cannot be 0");
        require(end.blockHash != 0, "End block hash cannot be 0");

        require(end.publicationId > start.publicationId, "End publication id must be greater than start publication id");
        require(end.blockNumber > start.blockNumber, "End block number must be greater than start block number");

        bytes32 startHash = keccak256(abi.encode(start));

        require(transitions[startHash].publicationId == 0, "transition already proven");

        // Verify the proof below

        // If the proof is valid, set the end checkpoint
        transitions[startHash] = end; // TODO: sometimes we do not need to save this transition
        emit TransitionProven(startHash, end);

        bytes32 endHash = keccak256(abi.encode(end));
        while (true) {
            Checkpoint memory nextCheckpoint = transitions[endHash];
            if (nextCheckpoint.publicationId == 0) break;

            lastStartHash = endHash;
            emit CheckpointProven(nextCheckpoint);
            
            endHash = keccak256(abi.encode(nextCheckpoint));
        }
    }
}
