// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {RingBuffer} from "../lib/RingBuffer.sol";
import {IDataFeed} from "./IDataFeed.sol";
import {IVerifier} from "./IVerifier.sol";

import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";

contract Inbox {
    using Arrays for uint256[];
    using RingBuffer for RingBuffer.CheckpointBuffer;

    /// @dev Tracks proven checkpoints after applying the publications at `_dataFeed`.
    /// A checkpoint is anything that describes the state of the rollup at a given data feed
    /// publication (e.g. a state root).
    RingBuffer.CheckpointBuffer private _checkpoints;

    IDataFeed public immutable _dataFeed;
    // This would usually be retrieved dynamically as in the current Taiko implementation, but for simplicity we are
    // just setting it in the constructor
    IVerifier public immutable _verifier;

    /// @notice Emitted when a checkpoint is proven
    /// @param pubIdx the index of the publication at which the checkpoint was proven
    /// @param checkpoint the checkpoint that was proven
    event CheckpointProven(uint256 indexed pubIdx, bytes32 indexed checkpoint);

    error AlreadyProven(uint256 index);
    error NotProven(uint256 index);

    /// @param bufferSize the maximum number of checkpoints simultaneously stored in this contract
    /// @param genesis the checkpoint describing the initial state of the rollup
    /// @param dataFeed the input data source that updates the state of this rollup
    /// @param verifier a contract that can verify the validity of a transition from one checkpoint to another
    constructor(uint256 bufferSize, bytes32 genesis, address dataFeed, address verifier) {
        // set the genesis checkpoint of the rollup - genesis is trusted to be correct
        require(genesis != 0, "genesis checkpoint cannot be 0");
        _checkpoints.setup(bufferSize);
        _checkpoints.setAt(0, genesis);
        _dataFeed = IDataFeed(dataFeed);
        _verifier = IVerifier(verifier);
    }

    /// @notice Returns the checkpoint at the given publication index
    /// @param at The index to query
    /// @return The checkpoint at the given index (wrapped around buffer length)
    function getCheckpoint(uint256 at) public view returns (bytes32) {
        require(_checkpoints.at(at).index == at);
        return _checkpoints.at(at).value;
    }

    /// @notice Returns the checkpoint at the last publication index
    /// @return The last checkpoint value
    function getLastCheckpoint() public view returns (bytes32) {
        return _checkpoints.last().value;
    }

    /// @notice Returns the last publication index
    /// @return The last publication index
    function getLastIndex() public view returns (uint256) {
        return _checkpoints.lastIndex();
    }

    /// @notice Proves the transition between two checkpoints
    /// @dev Updates the last index of elements in the buffer on success.
    /// @param start the index of the publication before this transition. Its checkpoint must already be proven.
    /// @param end the index of the last publication in this transition.
    /// @param checkpoint the claimed checkpoint at the end of this transition.
    /// @param proof arbitrary data passed to the `_verifier` contract to confirm the transition validity.
    function proveBetween(uint256 start, uint256 end, bytes32 checkpoint, bytes calldata proof) external {
        RingBuffer.Checkpoint storage startCheckpoint = _checkpoints.at(start);

        // Checks
        uint256 lastIndex = _checkpoints.lastIndex();
        require(start <= lastIndex && startCheckpoint.index == start, NotProven(start));
        require(end > lastIndex, AlreadyProven(end));

        // Do verify
        IVerifier(_verifier).verifyProof(
            _dataFeed.getPublicationHash(start),
            _dataFeed.getPublicationHash(end),
            startCheckpoint.value,
            checkpoint,
            proof
        );

        // Add checkpoint at the wrapped "end" position and update last index accordingly
        _checkpoints.setAt(end, checkpoint).setLastIndex(end);
        emit CheckpointProven(end, checkpoint);
    }
}
