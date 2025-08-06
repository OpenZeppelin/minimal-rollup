// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DefaultGasLimitScenario} from "./GasLimitScenarios.t.sol";
import {GenericRecipient} from "./GenericRecipient.t.sol";

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

abstract contract RelayRecipientScenarios is DefaultGasLimitScenario {}

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

// A valid scenario that can be used as a default scenario by unrelated tests.
abstract contract DefaultRelayRecipientScenario is RelayRecipentAcceptsMessage {}