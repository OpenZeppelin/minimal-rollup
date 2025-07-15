// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BridgeSufficientlyCapitalized} from "./CapitalizationScenarios.t.sol";
import {CrossChainDepositExists} from "./CrossChainDepositExists.t.sol";
import {TransferRecipient} from "./RecipientScenarios.t.sol";
import {RecipientIsAContract} from "./RecipientScenarios.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

/// This contract describes behaviours that should be valid when the deposit is cancelable.
abstract contract DepositIsCancelable is CrossChainDepositExists {
    function test_cancelDeposit_shouldSucceed() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));
        vm.prank(cancelerAddress);
        bridge.cancelDeposit(deposit, cancellationRecipient, HEIGHT, proof);
    }

    function test_cancelDeposit_shouldSetClaimedFlag() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));
        (, bytes32 id) = sampleDepositProof.getDepositInternals(_depositIdx());

        assertFalse(bridge.processed(id), "deposit already marked as claimed");

        vm.prank(cancelerAddress);
        bridge.cancelDeposit(deposit, cancellationRecipient, HEIGHT, proof);
        assertTrue(bridge.processed(id), "deposit not marked as claimed");
    }

    function test_cancelDeposit_shouldEmitEvent() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));
        (, bytes32 id) = sampleDepositProof.getDepositInternals(_depositIdx());

        vm.expectEmit();
        emit IETHBridge.DepositCancelled(id, cancellationRecipient);

        vm.prank(cancelerAddress);
        bridge.cancelDeposit(deposit, cancellationRecipient, HEIGHT, proof);
    }

    function test_cancelDeposit_shouldSendETH() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));

        uint256 initialCancellationRecipientBalance = cancellationRecipient.balance;
        uint256 initialRecipientBalance = recipient.balance;
        uint256 initialBridgeBalance = address(bridge).balance;

        vm.prank(cancelerAddress);
        bridge.cancelDeposit(deposit, cancellationRecipient, HEIGHT, proof);
        assertEq(recipient.balance, initialRecipientBalance, "recipient balance mismatch");
        assertEq(
            cancellationRecipient.balance,
            initialCancellationRecipientBalance + deposit.amount,
            "cancel recipient balance mismatch"
        );
        assertEq(address(bridge).balance, initialBridgeBalance - deposit.amount, "bridge balance mismatch");
    }

    function test_claimDeposit_shouldRevertWhen_DepositIsCancelled() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));

        vm.prank(cancelerAddress);
        bridge.cancelDeposit(deposit, cancellationRecipient, HEIGHT, proof);
        vm.expectRevert(IETHBridge.AlreadyProcessed.selector);
        bridge.claimDeposit(deposit, HEIGHT, proof);
    }

    function test_cancelDeposit_shouldRevertWhen_CancellerIsNotCaller() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));

        vm.expectRevert(IETHBridge.OnlyCanceler.selector);
        vm.prank(_randomAddress("notCanceller"));
        bridge.cancelDeposit(deposit, cancellationRecipient, HEIGHT, proof);
    }
}

abstract contract DepositIsNotCancelable is CrossChainDepositExists {
    function test_cancelDeposit_shouldRevertWhen_NoCancelerIsSet() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));

        vm.expectRevert(IETHBridge.OnlyCanceler.selector);
        vm.prank(cancelerAddress);
        bridge.cancelDeposit(deposit, cancellationRecipient, HEIGHT, proof);
    }
}

// This contract describes behaviours that should be valid when the deposit is a valid call
// to a recipient contract, and all other validity conditions are met.
abstract contract CancelableDepositIsValidContractCall is
    RecipientIsAContract,
    BridgeSufficientlyCapitalized,
    DepositIsCancelable
{
    function setUp()
        public
        virtual
        override(CrossChainDepositExists, RecipientIsAContract, BridgeSufficientlyCapitalized)
    {
        super.setUp();
    }

    function test_cancelDeposit_shouldNotInvokeRecipientContract() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));

        vm.expectCall(address(recipient), abi.encodeCall((TransferRecipient.somePayableFunction), (1234)), 0);

        vm.prank(cancelerAddress);
        bridge.cancelDeposit(deposit, recipient, HEIGHT, proof);
    }
}
