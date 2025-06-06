// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CrossChainDepositExists} from "./CrossChainDepositExists.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

/// This contract describes behaviours that should be valid when the deposit is claimable.
abstract contract DepositIsClaimableByRelayer is CrossChainDepositExists {
    function test_relayMessage_shouldSucceed() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));
        messageRelayer.relayMessage(deposit, HEIGHT, proof, address(0));
        // bridge.claimDeposit(deposit, HEIGHT, proof);
    }

    // function test_claimDeposit_shouldSetClaimedFlag() public {
    //     IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
    //     bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));
    //     (, bytes32 id) = sampleDepositProof.getDepositInternals(_depositIdx());
    //
    //     assertFalse(bridge.claimed(id), "deposit already marked as claimed");
    //     bridge.claimDeposit(deposit, HEIGHT, proof);
    //     assertTrue(bridge.claimed(id), "deposit not marked as claimed");
    // }
    //
    // function test_claimDeposit_shouldEmitEvent() public {
    //     IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
    //     bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));
    //     (, bytes32 id) = sampleDepositProof.getDepositInternals(_depositIdx());
    //
    //     vm.expectEmit();
    //     emit IETHBridge.DepositClaimed(id, deposit);
    //     bridge.claimDeposit(deposit, HEIGHT, proof);
    // }
    //
    // function test_claimDeposit_shouldSendETH() public {
    //     IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
    //     bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));
    //
    //     uint256 initialRecipientBalance = recipient.balance;
    //     uint256 initialBridgeBalance = address(bridge).balance;
    //
    //     bridge.claimDeposit(deposit, HEIGHT, proof);
    //     assertEq(recipient.balance, initialRecipientBalance + deposit.amount, "recipient balance mismatch");
    //     assertEq(address(bridge).balance, initialBridgeBalance - deposit.amount, "bridge balance mismatch");
    // }
}

/// This contract describes behaviours that should be valid when the deposit is not claimable.
abstract contract DepositIsNotClaimable is CrossChainDepositExists {
    function test_claimDeposit_shouldRevert() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));

        vm.expectRevert(IETHBridge.FailedClaim.selector);
        bridge.claimDeposit(deposit, HEIGHT, proof);
    }
}
