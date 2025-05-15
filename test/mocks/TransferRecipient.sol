// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract TransferRecipient {
    // Magic values to make the behaviour identifiable
    uint256 public constant REQUIRED_INPUT = 1234;
    uint256 public constant RETURN_VALUE = 5678;

    function someFunction(uint256 someArg) external payable returns (uint256) {
        require(someArg == REQUIRED_INPUT, "Invalid input");
        return RETURN_VALUE;
    }
}
