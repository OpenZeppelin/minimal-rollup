// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {UniversalTest} from "./UniversalTest.t.sol";

contract InitialStateTest is UniversalTest {
    function test_NonceIsZero() public view {
        assertEq(getNonce(), 0);
    }
}
