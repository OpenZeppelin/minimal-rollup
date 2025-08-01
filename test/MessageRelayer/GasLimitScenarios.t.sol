// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DepositRecipientIsMessageRelayer} from "./DepositRecipientScenarios.t.sol";
import {GenericRecipient} from "./GenericRecipient.t.sol";

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {IMessageRelayer} from "src/protocol/IMessageRelayer.sol";

contract UserSetGasLimit is DepositRecipientIsMessageRelayer {
    function setUp() public override {
        super.setUp();
    }

    function test_UserSetHighGasLimit_relayMessage_shouldRevert() public gasLimitHigherThanValue {
        vm.expectRevert(IETHBridge.FailedClaim.selector);
        _relayMessage();
    }

    function test_UserReasonableGasLimit_relayMessage() public whenGasLimitIsReasonable {
        vm.expectEmit();
        emit IMessageRelayer.MessageForwarded(address(to), amount - tip, data, address(userSelectedTipRecipient), tip);
        _relayMessage();
    }

    modifier gasLimitHigherThanValue() {
        gasLimit = amount + 1 wei;
        _encodeReceiveCall();
        _;
    }

    modifier whenGasLimitIsReasonable() {
        gasLimit = 100_000;
        _encodeReceiveCall();
        _;
    }
}
