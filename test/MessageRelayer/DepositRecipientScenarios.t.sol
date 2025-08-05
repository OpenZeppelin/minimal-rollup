// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {GenericRecipient} from "./GenericRecipient.t.sol";
import {InitialState} from "./InitialState.t.sol";

import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {IMessageRelayer} from "src/protocol/IMessageRelayer.sol";

// This is a concrete class because if we are not using the MessageRelayer,
// we do not need to investigate any other properties of the message
contract DepositRecipientIsNotMessageRelayer is InitialState {
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

abstract contract DepositRecipientIsMessageRelayer is InitialState {
    function test_DepositRecipientIsMessageRelayer_relayMessage_shouldInvokeReceiveMessage() public ifTxSucceeds {
        vm.expectCall(address(messageRelayer), ethDeposit.data);
        _relayMessage();
    }

    function test_DepositRecipientIsMessageRelayer_claimDeposit_shouldInvokeReceiveMessage() public ifTxSucceeds {
        vm.expectCall(address(messageRelayer), ethDeposit.data);
        messageRelayer.ethBridge().claimDeposit(ethDeposit, height, proof);
    }
}
