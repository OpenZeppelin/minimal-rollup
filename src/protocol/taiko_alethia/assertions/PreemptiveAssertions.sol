// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CalledByAnchor} from "./CalledByAnchor.sol";
import {IPreemptiveAssertions} from "./IPreemptiveAssertions.sol";
import {PublicationPauser} from "./PublicationPauser.sol";

contract PreemptiveAssertions is IPreemptiveAssertions, PublicationPauser {
    // Assertion statuses
    uint256 constant UNKNOWN = 0;
    uint256 constant UNPROVEN = 1;
    uint256 constant PROVEN = 2;

    uint256 public nUnproven;

    mapping(bytes32 assertionId => Assertion) private assertions;

    constructor(address _anchor) CalledByAnchor(_anchor) {}

    function createAssertion(bytes32 key, bytes32 val) external whenNotPaused {
        Assertion storage assertion = assertions[_assertionId(key)];
        require(!_exists(assertion), AssertionExists());
        assertion.status = UNPROVEN;
        assertion.value = val;
        nUnproven++;
    }

    function removeAssertion(bytes32 key) external {
        Assertion storage assertion = assertions[_assertionId(key)];
        require(_exists(assertion), AssertionDoesNotExist());
        if (assertion.status == UNPROVEN) {
            nUnproven--;
        }
        delete assertion.status;
        delete assertion.value;
    }

    /// @dev This should be used when the assertion has been proven but it should remain in the mapping
    /// so contracts can still query the value.
    function setProven(bytes32 key) external {
        Assertion storage assertion = assertions[_assertionId(key)];
        require(assertion.status == UNPROVEN, AssertionMustExistAndBeUnproven());
        assertion.status = PROVEN;
        nUnproven--;
    }

    function getAssertion(bytes32 key) external view returns (bytes32 value) {
        return getAssertion(key, msg.sender);
    }

    function getAssertion(bytes32 key, address asserter) public view returns (bytes32 value) {
        bytes32 assertionId = _assertionId(key, asserter);
        Assertion storage assertion = assertions[assertionId];
        require(_exists(assertion), AssertionDoesNotExist());
        return assertion.value;
    }

    function _assertionId(bytes32 key) internal view returns (bytes32) {
        return _assertionId(key, msg.sender);
    }

    function _assertionId(bytes32 key, address asserter) internal pure returns (bytes32) {
        return keccak256(abi.encode(asserter, key));
    }

    function _exists(Assertion storage assertion) internal view returns (bool) {
        return assertion.status != UNKNOWN;
    }
}
