// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";
import {IVerifier} from "./IVerifier.sol";

contract Inbox {
    // TODO: Optimize using the ring buffer design if we don't need to store all checkpoints
    // Checkpoints can be anything that describes the state of the rollup at a given publication(the most common case is
    // the state root)
    mapping(uint256 pubIdx => bytes32 checkpoint) checkpoints;

    uint256 lastProvenIdx;

    IDataFeed immutable _dataFeed;
    // This would usually be retrieved dinamically as in the current Taiko implementation, but for simplicity we are
    // just setting it on the constructor
    IVerifier immutable _verifier;

    constructor(bytes32 genesis, address dataFeed, address verifier) {
        // set the genesis state of the rollup - genesis is trusted to be correct
        checkpoints[0] = genesis;
        _dataFeed = IDataFeed(dataFeed);
        _verifier = IVerifier(verifier);
    }

    ///  @notice Proves that the transition between the start and end publication hashes is valid
    //          and updates the last proven index if checkpoint corresponds to a newer publication
    function proveBetween(uint256 start, uint256 end, bytes32 checkpoint, bytes calldata proof) external {
        bytes32 base = checkpoints[start];
        // this also ensures start <= lastProvenIdx
        require(base != 0, "Unknown base checkpoint");
        IVerifier(_verifier).verifyProof(
            _dataFeed.getPublicationHash(start), _dataFeed.getPublicationHash(end), base, checkpoint, proof
        );
        checkpoints[end] = checkpoint;

        lastProvenIdx = end > lastProvenIdx ? end : lastProvenIdx;
    }
}
