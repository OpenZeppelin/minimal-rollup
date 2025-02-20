// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";
import {IVerifier} from "./IVerifier.sol";

contract Inbox {
    struct Checkpoint {
        uint256 index;
        bytes32 value;
    }

    // TODO: Optimize using the ring buffer design if we don't need to store all checkpoints
    // Checkpoints can be anything that describes the state of the rollup at a given publication (the most common case
    // is the state root)
    /// @dev tracks proven checkpoints after applying the publication at `_dataFeed.getPublicationHash(pubIdx)`
    // mapping(uint256 pubIdx => bytes32 checkpoint) public checkpoints;
    mapping(uint256 pubIdx => Checkpoint checkpoint) private _checkpoints;

    /// @dev the highest `pubIdx` in `checkpoints`
    uint256 public lastProvenIdx;

    uint256 public immutable ringbufferSize;
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
    constructor(bytes32 genesis, address dataFeed, address verifier, uint256 _ringbufferSize) {
        // set the genesis checkpoint of the rollup - genesis is trusted to be correct
        require(genesis != 0, "genesis checkpoint cannot be 0");
        ringbufferSize = _ringbufferSize;
        _checkpoints[0] = Checkpoint(0, genesis);
        _dataFeed = IDataFeed(dataFeed);
        _verifier = IVerifier(verifier);
    }

    /// @notice Proves the transition between two checkpoints
    /// @dev Updates the `lastProvenIdx` to `end` on success
    /// @param start the index of the publication before this transition. Its checkpoint must already be proven.
    /// @param end the index of the last publication in this transition.
    /// @param checkpoint the claimed checkpoint at the end of this transition.
    /// @param proof arbitrary data passed to the `_verifier` contract to confirm the transition validity.
    function proveBetween(uint256 start, uint256 end, bytes32 checkpoint, bytes calldata proof) external {
        require(start <= lastProvenIdx, "Start checkpoint not proven");
        require(end > lastProvenIdx, "Publication already proven");
        require(checkpoint != 0, "Checkpoint cannot be 0");

        Checkpoint storage startCheckpoint = _checkpoints[start % ringbufferSize];
        require(startCheckpoint.index == start, "Start checkpoint not found");

        IVerifier(_verifier).verifyProof(
            _dataFeed.getPublicationHash(start),
            _dataFeed.getPublicationHash(end),
            startCheckpoint.value,
            checkpoint,
            proof
        );
        _checkpoints[end % ringbufferSize] = Checkpoint(end, checkpoint);
        lastProvenIdx = end;

        emit CheckpointProven(end, checkpoint);
    }
}
