// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IPublicationFeed} from "./IPublicationFeed.sol";
import {IVerifier} from "./IVerifier.sol";

struct ClaimedCheckpoint {
    uint256 publicationId;
    bytes32 checkpoint;
}

contract ParallelVerifications {
    IPublicationFeed public immutable publicationFeed;
    IVerifier public immutable verifier;

    mapping(bytes32 verifiedClaim => bytes32 putativeClaim) private verifications;

    constructor(address _publicationFeed, address _verifier) {
        publicationFeed = IPublicationFeed(_publicationFeed);
        verifier = IVerifier(_verifier);
    }

    function proveTransition(ClaimedCheckpoint calldata start, ClaimedCheckpoint calldata end, bytes calldata proof)
        external
    {
        bytes32 putativeHash = keccak256(abi.encode(start));
        bytes32 verifiedHash = keccak256(abi.encode(end));

        require(end.checkpoint != 0, "Checkpoint cannot be 0");
        // TODO: once the proving incentive mechanism is in place we should reconsider this requirement because
        // ideally we would use the proof that creates the longest chain of proven publications.
        require(verifiedHash == 0, "Already verified");
        require(start.publicationId < end.publicationId, "Start must be before end");
        require(end.publicationId < publicationFeed.getNextPublicationId(), "Publication does not exist");

        verifier.verifyProof(
            publicationFeed.getPublicationHash(start.publicationId),
            publicationFeed.getPublicationHash(end.publicationId),
            start.checkpoint,
            end.checkpoint,
            proof
        );

        verifications[verifiedHash] = putativeHash;
    }
}
