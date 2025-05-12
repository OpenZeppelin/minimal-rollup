// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {SignalService} from "src/protocol/SignalService.sol";

contract InitialState is Test {
    SignalService signalService;

    function setUp() public {
        signalService = new SignalService();
    }

    function _randomAddress(string memory name) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encode(_domainSeparator(), name)))));
    }

    function _domainSeparator() internal pure returns (bytes32) {
        return keccak256("SignalService");
    }
}