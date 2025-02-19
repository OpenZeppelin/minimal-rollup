// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";
import {IVerifier} from "./IVerifier.sol";
import {CircularBuffer} from "@openzeppelin/contracts/utils/structs/CircularBuffer.sol";

contract Inbox {
    using CircularBuffer for CircularBuffer.Bytes32CircularBuffer;

    /// @dev Tracks proven checkpoints after applying the publications at `_dataFeed`
    CircularBuffer.Bytes32CircularBuffer private _checkpoints;
    CircularBuffer.Bytes32CircularBuffer private _checkpointIdxs;

    IDataFeed public immutable _dataFeed;
    // This would usually be retrieved dynamically as in the current Taiko implementation, but for simplicity we are
    // just setting it in the constructor
    IVerifier public immutable _verifier;

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
        require(genesis != 0, "genesis checkpoint cannot be 0");
        _checkpoints.setup(bufferSize);
        _checkpointIdxs.setup(bufferSize);
        _checkpoints.push(genesis);
        _checkpointIdxs.push(0);
        _dataFeed = IDataFeed(dataFeed);
        _verifier = IVerifier(verifier);
    }

    function getCheckpoint(uint256 at) public view returns (bytes32) {
        return _checkpoints._data[at % _checkpoints.length()];
    }

    function checkpointsCount() public view returns (uint256) {
        return _checkpoints._count;
    }

    /// @notice Proves the transition between two checkpoints
    /// @dev Updates the count of elements in the buffer on success.
    /// @param start the index of the publication before this transition. Its checkpoint must already be proven.
    /// @param end the index of the last publication in this transition.
    /// @param checkpoint the claimed checkpoint at the end of this transition.
    /// @param proof arbitrary data passed to the `_verifier` contract to confirm the transition validity.
    function proveBetween(uint256 start, uint256 end, bytes32 checkpoint, bytes calldata proof) external {
        // Cache buffer length (remains constant)
        uint256 bufferLength = _checkpoints.length();
        uint256 atStart = start % bufferLength;

        // Checks
        require(_proven(start) && _checkpointIdxs._data[atStart] == bytes32(start), UnprovenIndex(start));
        require(!_proven(end), ProvenIndex(end));

        IVerifier(_verifier).verifyProof(
            _dataFeed.getPublicationHash(start),
            _dataFeed.getPublicationHash(end),
            _checkpoints._data[atStart],
            checkpoint,
            proof
        );

        // Add checkpoint at the wrapped "end" position and update count accordingly
        _checkpoints._count = end;
        uint256 atEnd = end % bufferLength;
        _checkpoints._data[atEnd] = checkpoint;
        _checkpointIdxs._data[atEnd] = bytes32(end); // Keep track of which index each publication belongs to
        emit CheckpointProven(end, checkpoint);
    }

    function _proven(uint256 index) private view returns (bool) {
        return index < _checkpoints.count();
    }
}
