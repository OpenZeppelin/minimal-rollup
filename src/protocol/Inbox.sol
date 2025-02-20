// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";
import {IVerifier} from "./IVerifier.sol";

contract Inbox {
    /// @notice Tracks the latest proven checkpoint for the Inbox
    /// @dev We don't store previous checkpoints, and instead synchronize them to the `SignalService` for messaging
    /// @dev A checkpoint is anything that uniquely identifies the state of the rollup at a given data feed
    /// publication (e.g. a state root).
    bytes32 public checkpoint;

    /// @notice The index of the last publication that was proven
    uint256 public lastProvenIdx;

    IDataFeed public immutable _dataFeed;
    // This would usually be retrieved dynamically as in the current Taiko implementation, but for simplicity we are
    // just setting it in the constructor
    IVerifier public immutable _verifier;

    /// @notice Emitted when a checkpoint is proven
    /// @param pubIdx the index of the publication at which the checkpoint was proven
    /// @param checkpoint the checkpoint that was proven
    event CheckpointProven(uint256 indexed pubIdx, bytes32 indexed checkpoint);

    /// @param genesis the checkpoint describing the initial state of the rollup
    /// @param dataFeed the input data source that updates the state of this rollup
    /// @param verifier a contract that can verify the validity of a transition from one checkpoint to another
    constructor(bytes32 genesis, address dataFeed, address verifier) {
        // set the genesis checkpoint of the rollup - genesis is trusted to be correct
        require(genesis != 0, "genesis checkpoint cannot be 0");
        checkpoint = genesis;
        _dataFeed = IDataFeed(dataFeed);
        _verifier = IVerifier(verifier);
    }

    /// @notice Proves the transition between the last proven checkpoint and a new checkpoint
    /// @dev Updates the `lastProvenIdx` to `end` on success
    /// @param end the index of the last publication in this transition.
    /// @param newCheckpoint the claimed checkpoint at the end of this transition.
    /// @param proof arbitrary data passed to the `_verifier` contract to confirm the transition validity.
    function proveTransition(uint256 end, bytes32 newCheckpoint, bytes calldata proof) external {
        require(checkpoint != 0, "Checkpoint cannot be 0");
        require(end > lastProvenIdx, "Publication already proven");

        IVerifier(_verifier).verifyProof(
            _dataFeed.getPublicationHash(lastProvenIdx),
            _dataFeed.getPublicationHash(end),
            checkpoint,
            newCheckpoint,
            proof
        );

        checkpoint = newCheckpoint;
        lastProvenIdx = end;

        emit CheckpointProven(end, checkpoint);
    }
}
