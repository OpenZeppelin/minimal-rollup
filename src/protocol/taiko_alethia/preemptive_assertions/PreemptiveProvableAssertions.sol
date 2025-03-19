// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {L1QueriesPublicationTime} from "./L1QueriesPublicationTime.sol";
import {PreemptiveProvableAssertionsBase} from "./PreemptiveProvableAssertionsBase.sol";

contract PreemptiveProvableAssertions is L1QueriesPublicationTime {
    constructor(address taikoAnchor) PreemptiveProvableAssertionsBase(taikoAnchor) {}
}
