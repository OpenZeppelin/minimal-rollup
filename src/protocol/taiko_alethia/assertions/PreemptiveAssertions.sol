// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IPreemptiveAssertions} from "./IPreemptiveAssertions.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract PreemptiveAssertions is IPreemptiveAssertions, Pausable {
    // Assertion statuses
    uint256 constant UNKNOWN = 0;
    uint256 constant UNPROVEN = 1;
    uint256 constant PROVEN = 2;

    uint256 public nUnproven;

    mapping(bytes32 assertionId => Assertion) private assertions;

    bytes32 private constant PAUSER_ID = keccak256("pauser");

    constructor() {
        _pause();
    }

    // PAUSE FUNCTIONALITY

    modifier onlyPauser() {
        require(assertions[PAUSER_ID].value == bytes32(uint256(uint160(msg.sender))), CallerIsNotPauser());
        _;
    }

    /// @dev There is no access control. The sequencer should ensure it is first called with a trusted address.
    /// @dev Use an assertion to save the pauser address, to guarantee it is cleared by the end of the publication
    function setPauser(address pauser) external {
        require(assertions[PAUSER_ID].status == UNKNOWN, "Pauser already set");
        _createAssertion(PAUSER_ID, bytes32(uint256(uint160(pauser))));
    }

    function removePauser() external onlyPauser {
        _removeAssertion(PAUSER_ID);
    }

    function pause() external onlyPauser {
        _pause();
    }

    function unpause() external onlyPauser {
        _unpause();
    }

    // ASSERTION FUNCTIONALITY

    function createAssertion(bytes32 key, bytes32 val) external whenNotPaused {
        _createAssertion(_assertionId(key), val);
    }

    function removeAssertion(bytes32 key) external {
        _removeAssertion(_assertionId(key));
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

    // INTERNAL FUNCTIONS

    function _createAssertion(bytes32 id, bytes32 val) internal {
        Assertion storage assertion = assertions[id];
        require(!_exists(assertion), AssertionExists());
        assertion.status = UNPROVEN;
        assertion.value = val;
        nUnproven++;
    }

    function _removeAssertion(bytes32 id) internal {
        Assertion storage assertion = assertions[id];
        require(_exists(assertion), AssertionDoesNotExist());
        if (assertion.status == UNPROVEN) {
            nUnproven--;
        }
        delete assertion.status;
        delete assertion.value;
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
