// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {PreemptiveAssertions} from "./PreemptiveAssertions.sol";

abstract contract Asserter {
    address public immutable anchor;
    PreemptiveAssertions public immutable preemptiveAssertions;

    error CallerNotAnchor();

    constructor(address _anchor, address _preemptiveAssertions) {
        anchor = _anchor;
        preemptiveAssertions = PreemptiveAssertions(_preemptiveAssertions);
    }

    modifier onlyAnchor() {
        require(msg.sender == anchor, CallerNotAnchor());
        _;
    }

    function resolve(bytes32[] calldata attributeHashes, bytes calldata proof) external onlyAnchor {
        _resolve(attributeHashes, proof);
    }

    function _resolve(bytes32[] calldata attributeHashes, bytes calldata proof) internal virtual;
}
