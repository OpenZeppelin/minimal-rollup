// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AmountExceedsTip} from "./FundAmountScenarios.t.sol";
import {GenericRecipient} from "./GenericRecipient.t.sol";

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {IMessageRelayer} from "src/protocol/IMessageRelayer.sol";

// Found by experimentation
uint256 constant OOG_INSIDE_RECIPIENT = 60_000;

// Use AmountExceedsTip as the default scenario.
// Any valid tip arrangement and funding amount should suffice for these tests.
abstract contract GasLimitScenarios is AmountExceedsTip {}

contract NoGasLimit_SufficientGasProvided is GasLimitScenarios {}

contract NoGasLimit_InsufficientGasProvided is GasLimitScenarios {
    function setUp() public override {
        super.setUp();
        gasProvidedWithCall = OOG_INSIDE_RECIPIENT;
        relayShouldSucceed = false;
        claimShouldSucceed = false;
    }
}

contract SufficientGasLimit_SufficientGasProvided is GasLimitScenarios {
    function setUp() public override {
        super.setUp();
        gasLimit = to.GAS_REQUIRED() + 100;
        _encodeReceiveCall();
    }
}

contract SufficientGasLimit_InsufficientGasProvided is GasLimitScenarios {
    function setUp() public override {
        super.setUp();
        gasLimit = to.GAS_REQUIRED() + 100;
        _encodeReceiveCall();
        gasProvidedWithCall = OOG_INSIDE_RECIPIENT;
        relayShouldSucceed = false;
        claimShouldSucceed = false;
    }
}

contract InsufficientGasLimit_SufficientGasProvided is GasLimitScenarios {
    function setUp() public override {
        super.setUp();
        // the amount forwarded to the recipient is slightly higher than gasLimit so deduct 150 as compensation
        // TODO: understand why this is necessary
        gasLimit = to.GAS_REQUIRED() - 150;
        _encodeReceiveCall();
        relayShouldSucceed = false;
        claimShouldSucceed = false;
    }
}
