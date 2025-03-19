// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @notice Allows an L2 proposer to inform L2 contracts about things that will be true at publication time.
/// Consider the scenario:
/// - the previous publication was posted to L1 at some time X
/// - the next publication will be posted to L1 at some future time Z
/// - the next proposer realises at some intermediate time Y that some claim will be provable on L1 by Z
/// - this typically involves either something that already happened on L1 or something the proposer chooses
/// Instead of waiting until Z
/// - the proposer asserts the claim using this L2 contract
/// - the state-transition function guarantees it will be proven by time Z, or the publication is a no-op
/// - other L2 contracts can rely on the claim as if it has already been proven
/// - this gets resolved at Z. Either the claim is proven or the publication is a no-op
/// @dev Deployed on L2
/// @dev This contract should be inherited to define specific assertion types supported by the rollup.
abstract contract PreemptiveProvableAssertionsBase {
    mapping(bytes32 assertionId => bool) internal exists;
    mapping(bytes32 assertionId => uint256) internal value;
    uint256 nAssertions;

    address immutable TAIKO_ANCHOR;

    constructor(address taikoAnchor) {
        TAIKO_ANCHOR = taikoAnchor;
    }

    /// @notice Can only be called by the TaikoAnchor contract
    /// @dev The Taiko state-transition function guarantees that the TaikoAnchor.anchor function is called as the first
    /// transaction (in the first L2 block) at the start of every publication.
    /// @dev In practice, this limits access control to the proposer (or builder) that constructs the L1 publication.
    modifier onlyAnchor() {
        require(msg.sender == TAIKO_ANCHOR, "Unauthorized");
        _;
    }

    /// whether all assertions have been proven
    function isResolved() public view returns (bool) {
        return nAssertions == 0;
    }

    function _assert(bytes32 assertionId, uint256 val) internal {
        require(!exists[assertionId]);
        exists[assertionId] = true;
        value[assertionId] = val;
        nAssertions++;
    }

    function _resolve(bytes32 assertionId) internal {
        require(exists[assertionId]);
        delete exists[assertionId];
        delete value[assertionId];
        nAssertions--;
    }
}
