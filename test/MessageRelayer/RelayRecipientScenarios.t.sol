// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DepositRecipientIsMessageRelayer} from "./DepositRecipientScenarios.t.sol";
import {GenericRecipient} from "./GenericRecipient.t.sol";

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

contract RelayRecipientRejectsDeposit is DepositRecipientIsMessageRelayer {
    function setUp() public override {
        super.setUp();
        to.setSuccess(false);
    }

    function test_RelayRecipientRejectsDeposit_relayMessage_shouldRevert() public {
        vm.expectRevert(IETHBridge.FailedClaim.selector);
        _relayMessage();
    }
}

contract RelayRecipientIsReentrant is DepositRecipientIsMessageRelayer {
    function setUp() public override {
        super.setUp();
        to.setReentrancyAttack(true);
    }

    function test_RelayRecipientReentersReceiveMessage_relayMessage_shouldRevert() public {
        vm.expectRevert(IETHBridge.FailedClaim.selector);
        _relayMessage();
    }
}
