// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {L1QueriesPublicationTime, L1Query} from "./L1QueriesPublicationTime.sol";
import {PreemptiveProvableAssertionsBase} from "./PreemptiveProvableAssertionsBase.sol";

contract PreemptiveProvableAssertions is L1QueriesPublicationTime {
    constructor(address taikoAnchor) PreemptiveProvableAssertionsBase(taikoAnchor) {}

    function registerAssertions(bytes calldata assertions) external onlyAnchor {
        (L1Query[] memory queries, uint256[] memory results) = abi.decode(assertions, (L1Query[], uint256[]));
        _assertL1QueryResults(queries, results);
    }
}
