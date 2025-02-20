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

    uint256 public immutable _ringbufferSize;
    IDataFeed public immutable _dataFeed;
    // This would usually be retrieved dynamically as in the current Taiko implementation, but for simplicity we are
    // just setting it in the constructor
    IVerifier public immutable _verifier;

    /// @notice Emitted when a checkpoint is proven
    /// @param pubIdx the index of the publication at which the checkpoint was proven
    /// @param checkpoint the checkpoint that was proven
    event CheckpointProven(uint256 indexed pubIdx, bytes32 indexed checkpoint);

    /// @param ringbufferSize the size of the ringbuffer used by checkpoints
    /// @param genesis the checkpoint describing the initial state of the rollup
    /// @param dataFeed the input data source that updates the state of this rollup
    /// @param verifier a contract that can verify the validity of a transition from one checkpoint to another
    constructor(uint256 ringbufferSize, bytes32 genesis, address dataFeed, address verifier) {
        require(ringbufferSize > 0, "Ringbuffer cannot be empty");
        _ringbufferSize = ringbufferSize;

        // set the genesis checkpoint of the rollup - genesis is trusted to be correct
        require(genesis != 0, "genesis checkpoint cannot be 0");
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

        IVerifier(_verifier).verifyProof(
            _dataFeed.getPublicationHash(start),
            _dataFeed.getPublicationHash(end),
            getCheckpoint(start),
            checkpoint,
            proof
        );

        Checkpoint storage endCheckpoint = _checkpointAt(end);
        endCheckpoint.index = end;
        endCheckpoint.value = checkpoint;

        lastProvenIdx = end;

        emit CheckpointProven(end, checkpoint);
    }

    function getCheckpoint(uint256 index) public view returns (bytes32) {
        Checkpoint storage checkpoint = _checkpointAt(index);
        require(checkpoint.index == index, "Checkpoint not found");
        return checkpoint.value;
    }

    function getLatestCheckpoint() public view returns (bytes32) {
        return _checkpointAt(lastProvenIdx).value;
    }

    function _checkpointAt(uint256 index) internal view returns (Checkpoint storage) {
        return _checkpoints[index % _ringbufferSize];
    }
}
