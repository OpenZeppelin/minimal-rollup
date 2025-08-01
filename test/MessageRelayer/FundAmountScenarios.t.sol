// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DepositRecipientIsMessageRelayer} from "./DepositRecipientScenarios.t.sol";
import {GenericRecipient} from "./GenericRecipient.t.sol";
import {IMessageRelayer} from "src/protocol/IMessageRelayer.sol";

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

contract VaryingFundAmounts is DepositRecipientIsMessageRelayer {
    function setUp() public override {
        super.setUp();
    }

    function test_SetZeroAmountWithTip_relayMessage_shouldRevert() public zeroAmount {
        vm.expectRevert(IETHBridge.FailedClaim.selector);
        _relayMessage();
    }

    function test_SetZeroAmountWithoutTip_relayMessage_shouldSucceed() public zeroTipZeroAmount {
        vm.expectEmit();
        emit IMessageRelayer.MessageForwarded(address(to), 0, data, address(userSelectedTipRecipient), 0);
        _relayMessage();
    }

    function test_SetTipHigherThanAmount_relayMessage_shouldRevert() public amountTooLow {
        vm.expectRevert(IETHBridge.FailedClaim.selector);
        _relayMessage();
    }

    modifier zeroTipZeroAmount() {
        tip = 0;
        ethDeposit.amount = 0;
        _encodeReceiveCall();
        _;
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
