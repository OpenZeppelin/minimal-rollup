// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {ETHBridge} from "src/protocol/ETHBridge.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

import {GenericRecipient} from "./GenericRecipient.t.sol";
import {IMessageRelayer} from "src/protocol/IMessageRelayer.sol";
import {MessageRelayer} from "src/protocol/taiko_alethia/MessageRelayer.sol";
import {MockSignalService} from "test/mocks/MockSignalService.sol";

// An explanation of the test structure:
// - we want to enumerate over several different configurations (eg. valid/invalid/zero tip recipients,
// sufficient/insufficient funds, eventual call succeeds/fails)
// - however, many of the tests are only relevant if the overall transaction succeeds, and this depends on settings
// defined in other files
// - ideally, we would only run the tests in the relevant scenario, but this would require less encapsulated logic
// - instead, the ifRelaySucceeds and ifClaimSucceeds modifiers are used to turn irrelevant tests into no-ops
// - the tests in this file ensure the transaction reverts when it is expected to

abstract contract InitialState is Test {
    MessageRelayer messageRelayer;
    ETHBridge bridge;

    // Default message parameters
    IETHBridge.ETHDeposit ethDeposit;
    uint256 height = 0;
    bytes proof = "0x";
    GenericRecipient to;
    uint256 amount = 2 ether;
    uint256 tip = 0.1 ether;
    GenericRecipient relayerSelectedTipRecipient;
    GenericRecipient userSelectedTipRecipient;
    uint256 gasLimit = 0;
    bytes data = "0x";

    // `claimDeposit` may fail when `relayMessage` succeeds, so these are separate flags
    bool relayShouldSucceed = true;
    bool claimShouldSucceed = true;

    uint256 gasProvidedWithCall = 150_000; // covers a full relayMessage call with some overhead

    function setUp() public virtual {
        MockSignalService signalService = new MockSignalService();
        signalService.setVerifyResult(true);
        address trustedCommitmentPublisher = makeAddr("trustedCommitmentPublisher");
        address counterpart = makeAddr("counterpart");
        bridge = new ETHBridge(address(signalService), trustedCommitmentPublisher, counterpart);
        vm.deal(address(bridge), amount);

        messageRelayer = new MessageRelayer(address(bridge));

        to = new GenericRecipient(address(messageRelayer));
        relayerSelectedTipRecipient = new GenericRecipient(address(messageRelayer));
        userSelectedTipRecipient = new GenericRecipient(address(messageRelayer));

        ethDeposit = IETHBridge.ETHDeposit({
            nonce: 0,
            from: makeAddr("from"),
            to: address(messageRelayer),
            amount: 2 ether,
            data: "",
            context: "",
            canceler: address(0)
        });
        _encodeReceiveCall();
    }

    function test_InitialState_relayMessage_shouldRevertWhenExpected() public {
        if (!relayShouldSucceed) {
            vm.expectRevert(IETHBridge.FailedClaim.selector);
            _relayMessage();
        }
    }

    function test_InitialState_claimDeposit_shouldRevertWhenExpected() public {
        if (!claimShouldSucceed) {
            vm.expectRevert(IETHBridge.FailedClaim.selector);
            _claimDeposit();
        }
    }

    function _encodeReceiveCall() internal {
        ethDeposit.data = abi.encodeCall(
            IMessageRelayer.receiveMessage, (address(to), tip, address(userSelectedTipRecipient), gasLimit, data)
        );
    }

    function _relayMessage() internal {
        messageRelayer.relayMessage{gas: gasProvidedWithCall}(
            ethDeposit, height, proof, address(relayerSelectedTipRecipient)
        );
    }

    function _claimDeposit() internal {
        bridge.claimDeposit{gas: gasProvidedWithCall}(ethDeposit, height, proof);
    }

    modifier ifRelaySucceeds() {
        if (relayShouldSucceed) {
            _;
        }
    }

    modifier ifClaimSucceeds() {
        if (claimShouldSucceed) {
            _;
        }
    }
}
