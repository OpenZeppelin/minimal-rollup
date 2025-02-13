// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";

import {IPreconfTaskManager} from "./IPreconfTaskManager.sol";
import {IVerifier} from "./IVerifier.sol";

contract Inbox {
    // TODO: Optimize using the ring buffer design if we don't need to store all checkpoints
    // Checkpoints can be anything that describes the state of the rollup at a given publication (the most common case
    // is the state root)
    /// @dev tracks proven checkpoints after applying the publication at `_dataFeed.getPublicationHash(pubIdx)`
    mapping(uint256 pubIdx => bytes32 checkpoint) checkpoints;

    /// @dev the highest `pubIdx` in `checkpoints`
    uint256 lastProvenIdx;

    IDataFeed immutable _dataFeed;
    // This would usually be retrieved dynamically as in the current Taiko implementation, but for simplicity we are
    // just setting it in the constructor
    IVerifier immutable _verifier;

    IPreconfTaskManager immutable _preconfer;

    /// @notice Emitted when a checkpoint is proven
    /// @param pubIdx the index of the publication at which the checkpoint was proven
    /// @param checkpoint the checkpoint that was proven
    event CheckpointProven(uint256 indexed pubIdx, bytes32 indexed checkpoint);

    /// @param genesis the checkpoint describing the initial state of the rollup
    /// @param dataFeed the input data source that updates the state of this rollup
    /// @param verifier a contract that can verify the validity of a transition from one checkpoint to another
    constructor(bytes32 genesis, address dataFeed, address verifier, address preconfTaskManager) {
        // set the genesis checkpoint of the rollup - genesis is trusted to be correct
        checkpoints[0] = genesis;
        _dataFeed = IDataFeed(dataFeed);
        _verifier = IVerifier(verifier);
        _preconfer = IPreconfTaskManager(preconfTaskManager);
    }

    /// @notice Proposes a checkpoint for a given publication, which needs to be proven at a later time
    /// @dev This function is restricted to the current preconfer, who has monopoly rights over L2 block production
    /// during certain slots
    function proposeCheckpoint(uint256 publicationIdx, bytes32 checkpoint) external {
        // check that the publication exists
        require(_dataFeed.getPublicationHash(publicationIdx) != 0, "Publication does not exist");

        // TODO: if there's any logic to deduct a liveness bond it would go here

        // Validate that only the current preconfer can propose the next checkpoint
        // Maybe we just send the current block number instead of the timestamp
        address currentPreconfer = _preconfer.getPreconfer(block.timestamp);
        require(msg.sender == currentPreconfer, "Not the current preconfer");

        checkpoints[publicationIdx] = checkpoint;
    }

    /// @notice Proves the transition between two checkpoints
    /// @dev Updates the `lastProvenIdx` to `end` on success
    /// @param start the index of the publication before this transition. Its checkpoint must already be proven.
    /// @param end the index of the last publication in this transition.
    /// @param checkpoint the claimed checkpoint at the end of this transition.
    /// @param proof arbitrary data passed to the `_verifier` contract to confirm the transition validity.
    // TODO: add logic for pausing the contract if there are conflicting proofs.
    // TODO: add an incentive mechanism for the prover, which can be abstracted in a separate IBondManager contract
    function proveBetween(uint256 start, uint256 end, bytes32 checkpoint, bytes calldata proof) external {
        require(end > lastProvenIdx, "Publication already proven");
        bytes32 base = checkpoints[start];
        // this also ensures start <= lastProvenIdx
        require(base != 0, "Unknown base checkpoint");

        IVerifier(_verifier).verifyProof(
            _dataFeed.getPublicationHash(start), _dataFeed.getPublicationHash(end), base, checkpoint, proof
        );
        checkpoints[end] = checkpoint;
        lastProvenIdx = end;

        emit CheckpointProven(end, checkpoint);
    }
}
