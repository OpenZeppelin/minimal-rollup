// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// TODO: decouple the generic inbox interface from the taiko_alethia implementation
import {CallSpecification} from "./taiko_alethia/assertions/PublicationTimeCall.sol";

interface IInbox {
    function publish(uint256 nBlobs, uint64 anchorBlockId, CallSpecification[] calldata callSpecs) external;
}
