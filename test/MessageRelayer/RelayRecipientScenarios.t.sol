// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {NoGasLimit_SufficientGasProvided} from "./GasLimitScenarios.t.sol";
import {GenericRecipient} from "./GenericRecipient.t.sol";

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

// Use NoGasLimit_SufficientGasProvided as the default scenario.
// Any valid tip arrangement, funding amount and gas limit should suffice for these tests.
abstract contract RelayRecipientScenarios is NoGasLimit_SufficientGasProvided {}

contract RelayRecipentAcceptsMessage is RelayRecipientScenarios {}

contract RelayRecipientRejectsMessage is RelayRecipientScenarios {
    function setUp() public override {
        super.setUp();
        to.setSuccess(false);
        relayShouldSucceed = false;
        claimShouldSucceed = false;
    }
}

contract RelayRecipientReentersReceiveMessage is RelayRecipientScenarios {
    function setUp() public override {
        super.setUp();
        to.setReentrancyAttack(true);
        relayShouldSucceed = false;
        claimShouldSucceed = false;
    }
}
