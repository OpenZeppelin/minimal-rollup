// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DepositIsCancelable} from "./CancelableScenarios.t.sol";
import {BridgeSufficientlyCapitalized} from "./CapitalizationScenarios.t.sol";
import {DepositIsClaimable, DepositIsNotClaimable} from "./ClaimableScenarios.t.sol";
import {CrossChainDepositExists} from "./CrossChainDepositExists.t.sol";
import {REQUIRED_INPUT, RecipientIsAContract, TransferRecipient} from "./RecipientScenarios.t.sol";
import {TransferRecipient} from "./RecipientScenarios.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

// This contract describes behaviours that should be valid when the deposit is a valid call
// to a recipient contract, and all other validity conditions are met.
abstract contract DepositIsValidContractCall is
    RecipientIsAContract,
    BridgeSufficientlyCapitalized,
    DepositIsClaimable
{
    function setUp()
        public
        virtual
        override(CrossChainDepositExists, RecipientIsAContract, BridgeSufficientlyCapitalized)
    {
        super.setUp();
    }

    function test_claimDeposit_shouldInvokeRecipientContract() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));

        vm.expectEmit();
        emit TransferRecipient.FunctionCalled();
        bridge.claimDeposit(deposit, HEIGHT, proof);
    }
}

// This contract describes behaviours that should be valid when the deposit is an invalid call
// to a recipient contract, and all other validity conditions are met.
abstract contract DepositIsInvalidContractCall is
    RecipientIsAContract,
    BridgeSufficientlyCapitalized,
    DepositIsNotClaimable
{
    function setUp()
        public
        virtual
        override(CrossChainDepositExists, RecipientIsAContract, BridgeSufficientlyCapitalized)
    {
        super.setUp();
    }
}

// This contract describes the secnario where a cancelable deposit is made but the canceler
// specifies a contract as the recipient.
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

    function test_cancelDeposit_canInvokeCancelerContract() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));

        bytes memory cancelCalldata = abi.encodeWithSignature("somePayableFunction(uint256)", (REQUIRED_INPUT));
        vm.prank(cancelerAddress);
        vm.expectEmit();
        emit TransferRecipient.FunctionCalled();
        bridge.cancelDeposit(deposit, recipient, cancelCalldata, HEIGHT, proof);
    }

    function test_cancelDeposit_shouldNotInvokeRecipientContract() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));

        vm.prank(cancelerAddress);
        vm.expectRevert(IETHBridge.FailedClaim.selector);
        bridge.cancelDeposit(deposit, recipient, "", HEIGHT, proof);
    }
}
