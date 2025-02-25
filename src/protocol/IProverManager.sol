// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {IPublicationFeed} from "./IPublicationFeed.sol";

interface IProverManager {
    function proveOwnPeriod(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader calldata endPublicationHeader,
        bytes calldata nextPublicationHeaderBytes,
        bytes calldata proof,
        uint256 periodId
    ) external;

    /// @notice Called by a prover when the originally assigned prover was evicted or passed its deadline for proving.
    function proveOtherPeriod(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader[] calldata publicationHeadersToProve, // these are the rollup's publications
        IPublicationFeed.PublicationHeader calldata nextPublicationHeader,
        bytes calldata proof,
        uint256 periodId
    ) external;
}
