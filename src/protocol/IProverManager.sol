// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {IPublicationFeed} from "./IPublicationFeed.sol";

interface IProverManager {
    /// @notice Bid to become the prover for the next period
    /// @param offeredFee The fee you are willing to charge for proving each publication
    function bid(uint256 offeredFee) external;

    /// @notice The current prover can signal exit to eventually pull out their liveness bond.
    function exit() external;

    /// @notice Evicts a prover that has been inactive, marking the prover for slashing
    /// @param publicationId The publication id that the caller is claiming is too old and hasn't been proven
    function evictProver(uint256 publicationId, IPublicationFeed.PublicationHeader calldata publicationHeader)
        external;

    function proveOpenPeriod(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader calldata startPublication,
        IPublicationFeed.PublicationHeader calldata endPublicationHeader,
        bytes calldata nextPublicationHeaderBytes,
        bytes calldata proof,
        uint256 periodId
    ) external;

    /// @notice Called by a prover when the originally assigned prover was evicted or passed its deadline for proving.
    function proveClosedPeriod(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader[] calldata publicationHeadersToProve, // these are the rollup's publications
        IPublicationFeed.PublicationHeader calldata nextPublicationHeader,
        bytes calldata proof,
        uint256 periodId
    ) external;
}
