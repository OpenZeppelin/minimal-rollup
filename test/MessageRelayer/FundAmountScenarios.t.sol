// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DepositRecipientIsMessageRelayer} from "./DepositRecipientScenarios.t.sol";
import {GenericRecipient} from "./GenericRecipient.t.sol";

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

contract VaryingFundAmount is DepositRecipientIsMessageRelayer {
    function setUp() public override {
        super.setUp();
    }

    function test_sentZeroAmount_relayMessage_shouldRevert() public zeroAmount {
        vm.expectRevert(IETHBridge.FailedClaim.selector);
        _relayMessage();
    }

    function test_setTipHigherThanAmount_relayMessage_shouldRevert() public amountTooLow {
        vm.expectRevert(IETHBridge.FailedClaim.selector);
        _relayMessage();
    }

    modifier zeroAmount() {
        ethDeposit.amount = 0;
        _encodeReceiveCall();
        _;
    }

    modifier amountTooLow() {
        ethDeposit.amount = tip - 1 wei;
        _encodeReceiveCall();
        _;
    }
}
