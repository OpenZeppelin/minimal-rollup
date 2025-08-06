// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {GenericRecipient} from "./GenericRecipient.t.sol";
import {ValidUserTipRecipientOverrulesRelayer} from "./TipRecipientScenarios.t.sol";
import {IMessageRelayer} from "src/protocol/IMessageRelayer.sol";

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

// Use ValidUserTipRecipientOverrulesRelayer as the default scenario.
// The particular tip arrangement should not affect these tests.
abstract contract FundAmountScenarios is ValidUserTipRecipientOverrulesRelayer {
    function test_FundAmountScenarios_relayMessage_shouldInvokeRecipient() public ifRelaySucceeds {
        vm.expectEmit();
        emit GenericRecipient.FunctionCalled();
        _relayMessage();
    }

    function test_FundAmountScenarios_relayMessage_shouldNotRetainFundsInRelayer() public ifRelaySucceeds {
        assertEq(address(messageRelayer).balance, 0, "relayer should not have funds");
        _relayMessage();
        assertEq(address(messageRelayer).balance, 0, "relayer should not retain funds");
    }

    function test_FundAmountScenarios_relayMessage_shouldSendAmountToRecipient() public ifRelaySucceeds {
        uint256 balanceBefore = address(to).balance;
        uint256 transferAmount = ethDeposit.amount - tip;
        _relayMessage();
        assertEq(address(to).balance, balanceBefore + transferAmount, "recipient balance mismatch");
    }

    function redundant_FundAmountScenarios_relayMessage_shouldSendTipToRecipient() public {
        // This test (if it were implemented) would be redundant with the tip recipient scenarios
        // It is included for completeness, so this file accounts for all the distributed funds
    }
}

contract AmountExceedsTip is FundAmountScenarios {}

contract NoAmountNoTip is FundAmountScenarios {
    function setUp() public override {
        super.setUp();
        ethDeposit.amount = 0;
        tip = 0;
        _encodeReceiveCall();
    }
}

contract NoAmountNonzeroTip is FundAmountScenarios {
    function setUp() public override {
        super.setUp();
        ethDeposit.amount = 0;
        relayShouldSucceed = false;
        claimShouldSucceed = false;
    }
}

contract AmountLessThanTip is FundAmountScenarios {
    function setUp() public override {
        super.setUp();
        ethDeposit.amount = tip - 1 wei;
        relayShouldSucceed = false;
        claimShouldSucceed = false;
    }
}
