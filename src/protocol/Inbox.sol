// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";
import {IVerifier} from "./IVerifier.sol";
import {CircularBuffer} from "@openzeppelin/contracts/utils/structs/CircularBuffer.sol";

contract Inbox {
    using CircularBuffer for CircularBuffer.Bytes32CircularBuffer;

    /// @dev Tracks proven checkpoints after applying the publications at `_dataFeed`
    CircularBuffer.Bytes32CircularBuffer private _checkpoints;

    IDataFeed immutable _dataFeed;
    // This would usually be retrieved dynamically as in the current Taiko implementation, but for simplicity we are
    // just setting it in the constructor
    IVerifier immutable _verifier;

    /// @notice Emitted when a checkpoint is proven
    /// @param pubIdx the index of the publication at which the checkpoint was proven
    /// @param checkpoint the checkpoint that was proven
    event CheckpointProven(uint256 indexed pubIdx, bytes32 indexed checkpoint);

    error ProvenIndex(uint256 index);
    error UnprovenIndex(uint256 index);

    /// @param bufferSize the maximum number of checkpoints simultaneously stored in this contract
    /// @param genesis the checkpoint describing the initial state of the rollup
    /// @param dataFeed the input data source that updates the state of this rollup
    /// @param verifier a contract that can verify the validity of a transition from one checkpoint to another
    constructor(uint256 bufferSize, bytes32 genesis, address dataFeed, address verifier) {
        // set the genesis checkpoint of the rollup - genesis is trusted to be correct
        _checkpoints.setup(bufferSize);
        _checkpoints.push(genesis);
        _dataFeed = IDataFeed(dataFeed);
        _verifier = IVerifier(verifier);
    }

    /// @notice Proves the transition between two checkpoints
    /// @dev Updates the count of elements in the buffer on success.
    /// @param start the index of the publication before this transition. Its checkpoint must already be proven.
    /// @param end the index of the last publication in this transition.
    /// @param checkpoint the claimed checkpoint at the end of this transition.
    /// @param proof arbitrary data passed to the `_verifier` contract to confirm the transition validity.
    function proveBetween(uint256 start, uint256 end, bytes32 checkpoint, bytes calldata proof) external {
        // Checks
        require(_proven(start), UnprovenIndex(start));
        require(!_proven(end), ProvenIndex(end));

        // Cache buffer length (remains constant)
        uint256 bufferLength = _checkpoints.length();

        IVerifier(_verifier).verifyProof(
            _dataFeed.getPublicationHash(start),
            _dataFeed.getPublicationHash(end),
            _checkpoints._data[start % bufferLength],
            checkpoint,
            proof
        );

        // Add checkpoint after N positions and increase count accordingly
        uint256 newCount = _checkpoints._count += (end - start);
        _checkpoints._data[newCount % bufferLength] = checkpoint;
        emit CheckpointProven(newCount, checkpoint);
    }

    function getCheckpoint(uint256 at) public view returns (bytes32) {
        return _checkpoints._data[at % _checkpoints.length()];
    }

    function _proven(uint256 index) private view returns (bool) {
        return index < _checkpoints.count();
    }
}
