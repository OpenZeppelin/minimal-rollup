// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DepositRecipientIsMessageRelayer} from "./DepositRecipientScenarios.t.sol";
import {GenericRecipient} from "./GenericRecipient.t.sol";

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

contract RelayRecipientScenarios is DepositRecipientIsMessageRelayer {
    function test_RelayRecipientRejectsDeposit_relayMessage_shouldRevert() public {
        to.setSuccess(false);
        vm.expectRevert(IETHBridge.FailedClaim.selector);
        _relayMessage();
    }

    function test_RelayRecipientReentersReceiveMessage_relayMessage_shouldRevert() public {
        to.setReentrancyAttack(true);
        vm.expectRevert(IETHBridge.FailedClaim.selector);
        _relayMessage();
    }
}
