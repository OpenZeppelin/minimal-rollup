// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract CalledByAnchor {
    address public immutable anchor;

    error CallerIsNotAnchor();

    constructor(address _anchor) {
        anchor = _anchor;
    }

    modifier onlyAnchor() {
        require(msg.sender == anchor, CallerIsNotAnchor());
        _;
    }
}
