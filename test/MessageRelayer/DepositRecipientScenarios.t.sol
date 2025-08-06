// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {GenericRecipient} from "./GenericRecipient.t.sol";
import {InitialState} from "./InitialState.t.sol";

import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {IMessageRelayer} from "src/protocol/IMessageRelayer.sol";

abstract contract DepositRecipientScenarios is InitialState {}

contract DepositRecipientIsMessageRelayer is DepositRecipientScenarios {
    function test_DepositRecipientIsMessageRelayer_relayMessage_shouldInvokeReceiveMessage() public ifRelaySucceeds {
        vm.expectCall(address(messageRelayer), ethDeposit.data);
        _relayMessage();
    }

    function test_DepositRecipientIsMessageRelayer_claimDeposit_shouldInvokeReceiveMessage() public ifClaimSucceeds {
        vm.expectCall(address(messageRelayer), ethDeposit.data);
        _claimDeposit();
    }
}

contract DepositRecipientIsNotMessageRelayer is DepositRecipientScenarios {
    function setUp() public override {
        super.setUp();
        // bypass the relayer and send the message directly to the recipient
        // do not bother changing the default message encoding (to a `receiveMessage` function)
        // because the recipient handles any message
        ethDeposit.to = address(to);
    }

    function test_DepositRecipientIsNotMessageRelayer_relayMessage_shouldInvokeRecipient() public {
        vm.expectEmit();
        emit GenericRecipient.FunctionCalled();
        _relayMessage();
    }

    function test_DepositRecipientIsNotMessageRelayer_relayMessage_shouldNotInvokeReceiveMessage() public {
        vm.expectCall(address(messageRelayer), ethDeposit.data, 0);
        _relayMessage();
    }
}

// A valid scenario that can be used as a default scenario by unrelated tests.
abstract contract DefaultRecipientScenario is DepositRecipientScenarios {}