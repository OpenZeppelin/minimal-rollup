// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/console.sol";

import {CrossChainDepositExists} from "./CrossChainDepositExists.t.sol";

import {MessageRelayer} from "src/protocol/taiko_alethia/MessageRelayer.sol";

/// This contract describes behaviours that should be valid when the deposit recipient is a TransferRecipient contract.
abstract contract RecipientIsAContract is CrossChainDepositExists {
    function setUp() public virtual override {
        super.setUp();
        // Set the recipient to be a TransferRecipient contract
        deployCodeTo("TransferRecipient", recipient);
    }
}

abstract contract RecipientIsRelayer is CrossChainDepositExists {
    function setUp() public virtual override {
        super.setUp();
        messageRelayer = new MessageRelayer(address(bridge));
        tipRecipient = _randomAddress("tipRecipient");
    }
}

/// This contract describes behaviours that should be valid when the deposit recipient is an EOA.
abstract contract RecipientIsAnEOA is CrossChainDepositExists {
// no need to do anything because the recipient defaults to no code
}

contract TransferRecipient {
    // Magic values to make the behaviour identifiable
    uint256 public constant REQUIRED_INPUT = 1234;
    uint256 public constant RETURN_VALUE = 5678;

    event FunctionCalled();

    // valid calldata: 0x9b28f6fb00000000000000000000000000000000000000000000000000000000000004d2
    function somePayableFunction(uint256 someArg) external payable returns (uint256) {
        require(someArg == REQUIRED_INPUT, "Invalid input");
        emit FunctionCalled();
        return RETURN_VALUE;
    }

    // valid calldata: 0x5932a71200000000000000000000000000000000000000000000000000000000000004d2
    function someNonpayableFunction(uint256 someArg) external returns (uint256) {
        require(someArg == REQUIRED_INPUT, "Invalid input");
        emit FunctionCalled();
        return RETURN_VALUE;
    }
}
