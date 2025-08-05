// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DepositRecipientIsMessageRelayer} from "./DepositRecipientScenarios.t.sol";
import {GenericRecipient} from "./GenericRecipient.t.sol";

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

import {console} from "forge-std/console.sol";

contract UserSetTipRecipientScenarios is DepositRecipientIsMessageRelayer {
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

    function test_UserSetValidTipRecipient_claimDepositDirectly_shouldTipUserSelectedRecipient() public {
        uint256 balanceBefore = address(userSelectedTipRecipient).balance;
        bridge.claimDeposit(ethDeposit, height, proof);
        assertEq(address(userSelectedTipRecipient).balance, balanceBefore + tip, "tip recipient balance mismatch");
    }

    function test_UserSetZeroTipRecipient_relayMessage_shouldTipRelayerSelectedRecipient() public zeroTipRecipient {
        uint256 balanceBefore = address(relayerSelectedTipRecipient).balance;
        _relayMessage();
        assertEq(address(relayerSelectedTipRecipient).balance, balanceBefore + tip, "tip recipient balance mismatch");
    }

    function test_UserSetZeroTipRecipient_claimDepositDirectly_shouldRevert() public zeroTipRecipient {
        uint256 relayerTipRecipientBalanceBefore = address(relayerSelectedTipRecipient).balance;
        vm.expectRevert(IETHBridge.FailedClaim.selector);
        bridge.claimDeposit(ethDeposit, height, proof);
        assertEq(
            address(relayerSelectedTipRecipient).balance,
            relayerTipRecipientBalanceBefore,
            "tip recipient balance mismatch"
        );
    }

    modifier zeroTipRecipient() {
        userSelectedTipRecipient = GenericRecipient(payable(0));
        _encodeReceiveCall();
        _;
    }
}

contract UserSetInvalidTipRecipient is DepositRecipientIsMessageRelayer {
    function setUp() public override {
        super.setUp();
        userSelectedTipRecipient.setSuccess(false);
        txShouldSucceed = false;
    }

    function test_UserSetInvalidTipRecipient_relayMessage_shouldRevert() public {
        vm.expectRevert(IETHBridge.FailedClaim.selector);
        _relayMessage();
    }
}
