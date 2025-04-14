// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {BaseState} from "./SignalService.t.sol";

import {ETHBridge} from "src/protocol/ETHBridge.sol";

import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

// represents state where a deposit is made on L1
// however, the state root is not yet available on L2
contract BridgeETHState is BaseState {
    // 0xf9c183d2de58fbeb1a8917170139e980fa1b6e5a358ec83721e11c9f6e25eb18
    bytes32 public depositIdOne;
    uint256 public depositAmount = 4 ether;
    ETHBridge.ETHDeposit public depositOne;

    // this is a valid deposit ID but is sent via a signal not a deposit
    // hence "invalid" and should not be claimable
    bytes32 invalidDepositId = 0xbf8ce3088406c4ddbc32e32404ca006c3ef57f07d5139479f16c9124d6490f2e;

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(L1Fork);

        vm.prank(defaultSender);
        bytes memory emptyData = "";
        vm.recordLogs();
        depositIdOne = L1signalService.deposit{value: depositAmount}(defaultSender, emptyData);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        depositOne = abi.decode(entries[0].data, (IETHBridge.ETHDeposit));
        console.log("depositOne", depositOne.nonce);

        vm.prank(defaultSender);
        L1signalService.sendSignal(invalidDepositId);
    }
}

contract ETHBridgeTest is BridgeETHState {
    function test_initialDepositState() public {
        assertEq(address(L1signalService).balance, ETHBridgeInitBalance + depositAmount);
        assertEq(defaultSender.balance, senderBalanceL1 - depositAmount);

        vm.selectFork(L2Fork);
        assertEq(L2signalService.claimed(depositIdOne), false);
        assertEq(defaultSender.balance, senderBalanceL2);
    }
}

contract CommitmentStoredState is BridgeETHState {
    bytes32 public stateRoot = hex"04968238447626aae6b80256424c21fc86d3d0a83e9820fb6f6031a3f0084224";
    bytes32 public storageRoot = hex"a4d3f4f073780c1bdd2bb3f3f067779a5b41fb81bfe882f2e2cc13af60cf95b7";
    uint256 public commitmentHeight = 1;

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(L2Fork);
        anchor.anchor(commitmentHeight, stateRoot);
    }

    function accountProofSignalService() public pure returns (bytes[] memory accountProofArr) {
        accountProofArr = new bytes[](3);
        accountProofArr[0] =
            hex"f90131a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0cee292ed472a7a4b0ad1104b5fa77172cc8305a1e3a150d35e7d8b53548f3853a04f1861a2e3ee7a77b7e9341406be8f4422097e74e0dc7ff9b7c52fab91a68e3d8080a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a01c30cc3f9e8f1986719641358e4987ec4bb2a0e793956f929870ac689ad5d18ea0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProofArr[1] =
            hex"f85180808080a0a724b22e6df6f7bcb23a26a2d5781e55cb883854277cc785f7145ad36a56263280808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProofArr[2] =
            hex"f871a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb84ef84c01883782dace9d900000a0a4d3f4f073780c1bdd2bb3f3f067779a5b41fb81bfe882f2e2cc13af60cf95b7a082b5a68e8d4087a7132e9f24fa54d04cc635bec5a6e773152eac141eeff8309d";
    }

    function storageProofDepositOne() public pure returns (bytes[] memory storageProofArr) {
        storageProofArr = new bytes[](2);
        storageProofArr[0] =
            hex"f89180808080a015ae32d5986f7e597e8a4db519e6640db0eeb8271f30c7691dc58cd99b9cae8da0f45718ab57bfc532ca0fff4f84bca07a0d28280f2b6cee5c0e4bce4f62790eef8080808080a0f4984a11f61a2921456141df88de6e1a710d28681b91af794c5a721e47839cd780a060be43426df604212322c09fe9045ffb7543b0bcd0f927cd90fed17ea5057912808080";
        storageProofArr[1] =
            hex"f843a03e489ae456a515de885d39c5188bcd6169574db5667aa9ba76cfe7c1e9afc5fea1a0f9c183d2de58fbeb1a8917170139e980fa1b6e5a358ec83721e11c9f6e25eb18";
    }

    function storageProofInvalidDeposit() public pure returns (bytes[] memory storageProofArr) {
        storageProofArr = new bytes[](2);

        storageProofArr[0] =
            hex"f89180808080a015ae32d5986f7e597e8a4db519e6640db0eeb8271f30c7691dc58cd99b9cae8da0f45718ab57bfc532ca0fff4f84bca07a0d28280f2b6cee5c0e4bce4f62790eef8080808080a0f4984a11f61a2921456141df88de6e1a710d28681b91af794c5a721e47839cd780a060be43426df604212322c09fe9045ffb7543b0bcd0f927cd90fed17ea5057912808080";
        storageProofArr[1] =
            hex"f843a03e4b9f05a3709e8b7aeb7ad23c6304cc7c352036e185309eb9ca85a9d479a4bca1a0bf8ce3088406c4ddbc32e32404ca006c3ef57f07d5139479f16c9124d6490f2e";
    }
}

contract ClaimDepositTest is CommitmentStoredState {
    function test_claimDeposit() public {
        vm.selectFork(L2Fork);

        bytes[] memory accountProof = accountProofSignalService();
        bytes[] memory storageProof = storageProofDepositOne();
        ISignalService.SignalProof memory signalProof = ISignalService.SignalProof(accountProof, storageProof);
        bytes memory encodedProof = abi.encode(signalProof);

        L2signalService.claimDeposit(depositOne, commitmentHeight, encodedProof);

        assertEq(address(L2signalService).balance, ETHBridgeInitBalance - depositAmount);
        assertEq(defaultSender.balance, senderBalanceL2 + depositAmount);
    }

    function test_claimDeposit_RevertWhen_SentViaSignalNotDeposit() public {
        bytes[] memory accountProof = accountProofSignalService();
        bytes[] memory storageProof = storageProofInvalidDeposit();
        ISignalService.SignalProof memory signalProof = ISignalService.SignalProof(accountProof, storageProof);
        bytes memory encodedProof = abi.encode(signalProof);

        ETHBridge.ETHDeposit memory invalidDeposit;
        invalidDeposit.nonce = 1;
        invalidDeposit.from = defaultSender;
        invalidDeposit.to = defaultSender;
        invalidDeposit.amount = depositAmount;
        invalidDeposit.data = "";

        vm.selectFork(L1Fork);
        bool storedInGenericNamespace =
            L1signalService.isSignalStored(invalidDepositId, defaultSender, keccak256("generic-signal"));
        assertTrue(storedInGenericNamespace);

        bool storedInEthBridgeNamespace =
            L1signalService.isSignalStored(invalidDepositId, defaultSender, keccak256("eth-bridge"));
        assertFalse(storedInEthBridgeNamespace);

        vm.selectFork(L2Fork);
        // to be extra sure its not a problem with the proof
        L2signalService.verifySignal(commitmentHeight, defaultSender, invalidDepositId, encodedProof);
        // I believe this error means that the proof is not valid for this deposit id
        vm.expectRevert("MerkleTrie: invalid large internal hash");
        L2signalService.claimDeposit(invalidDeposit, commitmentHeight, encodedProof);
    }
}
