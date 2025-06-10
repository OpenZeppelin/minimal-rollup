// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IPreemptiveAssertions {
    struct Assertion {
        uint256 status;
        bytes32 value;
    }

    error AssertionExists();
    error AssertionDoesNotExist();
    error AssertionMustExistAndBeUnproven();
}
