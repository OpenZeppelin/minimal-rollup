// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DepositRecipientIsMessageRelayer} from "./DepositRecipientScenarios.t.sol";
import {GenericRecipient} from "./GenericRecipient.t.sol";

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

contract UserSetValidTipRecipient is DepositRecipientIsMessageRelayer {
    function test_UserSetValidTipRecipient_relayMessage_shouldTipUserSelectedRecipient() public {
        uint256 balanceBefore = address(userSelectedTipRecipient).balance;
        _relayMessage();
        assertEq(address(userSelectedTipRecipient).balance, balanceBefore + tip, "tip recipient balance mismatch");
    }

    function test_UserSetValidTipRecipient_relayMessage_shouldNotTipRelayerSelectedRecipient() public {
        uint256 balanceBefore = address(relayerSelectedTipRecipient).balance;
        _relayMessage();
        assertEq(address(relayerSelectedTipRecipient).balance, balanceBefore, "incorrect tip recipient paid");
    }
}

contract UserSetZeroTipRecipient is DepositRecipientIsMessageRelayer {
    function setUp() public override {
        super.setUp();
        userSelectedTipRecipient = GenericRecipient(payable(0));
        _encodeReceiveCall();
    }

    function test_UserSetZeroTipRecipient_relayMessage_shouldTipRelayerSelectedRecipient() public {
        uint256 balanceBefore = address(relayerSelectedTipRecipient).balance;
        _relayMessage();
        assertEq(address(relayerSelectedTipRecipient).balance, balanceBefore + tip, "tip recipient balance mismatch");
    }
}

// We bypass the `DepositRecipientIsMessageRelayer` because it seems vm.expectCall requires the call to succeed
contract UserSetInvalidTipRecipient is InitialState {
    function setUp() public override {
        super.setUp();
        userSelectedTipRecipient.setSuccess(false);
    }

    function test_UserSetInvalidTipRecipient_relayMessage_shouldRevert() public {
        vm.expectRevert(IETHBridge.FailedClaim.selector);
        _relayMessage();
    }
}
