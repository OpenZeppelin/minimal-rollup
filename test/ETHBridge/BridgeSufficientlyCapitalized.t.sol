// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CrossChainDepositExists} from "./CrossChainDepositExists.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

/// This contract describes behaviours that should be valid when the local bridge has
/// enough ether to cover the cross chain deposit.
/// On L1, this would be from a previous deposit (to the L2).
/// On L2, we assume the bridge is prefunded.
contract BridgeSufficientlyCapitalized is CrossChainDepositExists {

    uint256 constant private DEPOSIT_IDX = 0; // a deposit index with non-zero amount

    function setUp() public virtual override {
        super.setUp();
        vm.deal(address(bridge), sampleDepositProof.getEthDeposit(DEPOSIT_IDX).amount);
    }

    function test_claimDeposit_shouldSucceed() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(DEPOSIT_IDX);
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(DEPOSIT_IDX));
        bridge.claimDeposit(deposit, HEIGHT, proof);
    }

    function test_claimDeposit_shouldSetClaimedFlag() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(DEPOSIT_IDX);
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(DEPOSIT_IDX));
        (, bytes32 id) = sampleDepositProof.getDepositInternals(DEPOSIT_IDX);

        assertFalse(bridge.claimed(id), "deposit already marked as claimed");
        bridge.claimDeposit(deposit, HEIGHT, proof);
        assertTrue(bridge.claimed(id), "deposit not marked as claimed");
    }

    function test_claimDeposit_shouldEmitEvent() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(DEPOSIT_IDX);
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(DEPOSIT_IDX));
        (, bytes32 id) = sampleDepositProof.getDepositInternals(DEPOSIT_IDX);

        vm.expectEmit();
        emit IETHBridge.DepositClaimed(id, deposit);
        bridge.claimDeposit(deposit, HEIGHT, proof);
    }

    function test_claimDeposit_shouldSendETH() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(DEPOSIT_IDX);
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(DEPOSIT_IDX));

        uint256 initialRecipientBalance = recipient.balance;
        uint256 initialBridgeBalance = address(bridge).balance;

        bridge.claimDeposit(deposit, HEIGHT, proof);
        assertEq(recipient.balance, initialRecipientBalance + deposit.amount, "recipient balance mismatch");
        assertEq(address(bridge).balance, initialBridgeBalance - deposit.amount, "bridge balance mismatch");
    }
}
