// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DefaultFundAmountScenario} from "./FundAmountScenarios.t.sol";
import {GenericRecipient} from "./GenericRecipient.t.sol";

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {IMessageRelayer} from "src/protocol/IMessageRelayer.sol";

// Found by experimentation
uint256 constant OOG_INSIDE_RECIPIENT = 60_000;

abstract contract GasLimitScenarios is DefaultFundAmountScenario {}

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

// A valid scenario that can be used as a default scenario by unrelated tests.
abstract contract DefaultGasLimitScenario is NoGasLimit_SufficientGasProvided {}
