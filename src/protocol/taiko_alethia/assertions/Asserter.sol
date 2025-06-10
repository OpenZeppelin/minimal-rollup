// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CalledByAnchor} from "./CalledByAnchor.sol";
import {PreemptiveAssertions} from "./PreemptiveAssertions.sol";

abstract contract Asserter is CalledByAnchor {
    PreemptiveAssertions public immutable preemptiveAssertions;

    constructor(address _preemptiveAssertions) {
        preemptiveAssertions = PreemptiveAssertions(_preemptiveAssertions);
    }

    function resolve(bytes32[] calldata attributeHashes, bytes calldata proof) external onlyAnchor {
        _resolve(attributeHashes, proof);
    }

    function _resolve(bytes32[] calldata attributeHashes, bytes calldata proof) internal virtual;
}
