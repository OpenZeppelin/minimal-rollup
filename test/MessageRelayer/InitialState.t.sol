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
// - instead, the ifTxSucceeds modifier is used to turn irrelevant tests into no-ops

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

    bool txShouldSucceed = true;

    // keccak256("TIP_RECIPIENT_SLOT")
    bytes32 constant TIP_RECIPIENT_SLOT = 0x833ce1785f54a5ca49991a09a7b058587309bf3687e5f20b7b66fa12132ef6f0;

    function setUp() public virtual {
        MockSignalService signalService = new MockSignalService();
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

    function _encodeReceiveCall() internal {
        ethDeposit.data = abi.encodeCall(
            IMessageRelayer.receiveMessage, (address(to), tip, address(userSelectedTipRecipient), gasLimit, data)
        );
    }

    function _relayMessage() internal {
        messageRelayer.relayMessage(ethDeposit, height, proof, address(relayerSelectedTipRecipient));
    }

    modifier ifTxSucceeds() {
        if (txShouldSucceed) {
            _;
        }
    }
}
