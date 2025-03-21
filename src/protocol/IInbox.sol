// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// TODO: decouple the generic inbox interface from the taiko_alethia implementation
import {L1Query} from "./taiko_alethia/preemptive_assertions/L1QueriesPublicationTime.sol";

interface IInbox {
    function publish(uint256 nBlobs, uint64 anchorBlockId, L1Query[] calldata queries) external;
}
