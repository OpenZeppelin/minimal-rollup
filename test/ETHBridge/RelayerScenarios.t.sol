// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CrossChainDepositExists} from "./CrossChainDepositExists.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {IMessageRelayer} from "src/protocol/IMessageRelayer.sol";

/// This contract describes behaviours that should be valid when the deposit is claimable.
abstract contract DepositIsClaimableByRelayer is CrossChainDepositExists {
    function test_relayMessage_shouldSucceed() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));
        messageRelayer.relayMessage(deposit, HEIGHT, proof, tipRecipient);
    }

    function test_relayMessage_shouldSetClaimedFlag() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));
        (, bytes32 id) = sampleDepositProof.getDepositInternals(_depositIdx());

        assertFalse(bridge.claimed(id), "deposit already marked as claimed");
        messageRelayer.relayMessage(deposit, HEIGHT, proof, tipRecipient);
        assertTrue(bridge.claimed(id), "deposit not marked as claimed");
    }

    function test_relayMessage_shouldEmitEvent() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));
        (, bytes32 id) = sampleDepositProof.getDepositInternals(_depositIdx());

        vm.expectEmit();
        emit IMessageRelayer.MessageForwarded(
            recipient, deposit.amount - tipAmount, new bytes(0), tipRecipient, tipAmount
        );
        vm.expectEmit();
        emit IETHBridge.DepositClaimed(id, deposit);
        messageRelayer.relayMessage(deposit, HEIGHT, proof, tipRecipient);
    }

    function test_relayMessage_shouldSendETH() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));

        uint256 initialRecipientBalance = recipient.balance;
        uint256 initialTipRecipientBalance = tipRecipient.balance;
        uint256 initialBridgeBalance = address(bridge).balance;

        messageRelayer.relayMessage(deposit, HEIGHT, proof, tipRecipient);
        assertEq(recipient.balance, initialRecipientBalance + deposit.amount - tipAmount, "recipient balance mismatch");
        assertEq(address(bridge).balance, initialBridgeBalance - deposit.amount, "bridge balance mismatch");
        assertEq(tipRecipient.balance, initialTipRecipientBalance + tipAmount, "tip recipient balance mismatch");
    }
}
