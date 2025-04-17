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
    bytes32 invalidDepositId = 0xc9c38023fccb0f40eb13158a43adb58b864737eaf95c112b795e4bc6eb390e79;

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(L1Fork);

        vm.prank(defaultSender);
        bytes memory emptyData = "";
        vm.recordLogs();
        depositIdOne = L1signalService.deposit{value: depositAmount}(defaultSender, L2ChainId, emptyData);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        depositOne = abi.decode(entries[0].data, (IETHBridge.ETHDeposit));

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
    bytes32 public stateRoot = hex"4066a712204e3e382dded70283152bc193d2dd2723785db86d819454f644be05";
    uint256 public commitmentHeight = 1;

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(L2Fork);
        anchor.anchor(commitmentHeight, stateRoot);
    }

    function accountProofSignalService() public pure returns (bytes[] memory accountProofArr) {
        accountProofArr = new bytes[](3);

        accountProofArr[0] =
            hex"f90131a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a056dc093a5c10f342d85933dc7cd8bb9ee0cc0b490ae5a03d624f3d82469b3686a0ebfc19e87dcaddfa5601abfc75cb41ea61657f3bce80c31a518611fc7ba9b1698080a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0809b70d0f09f0d53aed5487d0aafadc6357b429c43248ec0246a3433598d5ef3a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProofArr[1] =
            hex"f85180808080a01a6a724a7a2827a0e134565d73cf3a1d6b1e5439fb9433d2d6d17bfba5b329f080808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProofArr[2] =
            hex"f871a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb84ef84c01883782dace9d900000a06e729ae3f1a09bc7964410fbb1d91db87b0e8d305599fc5dd2d82d1581de3c14a0ddfe133f8d0695ac1f20fc88dcdc608589d64d03d20e948e7486d381b9e2c426";
    }

    function storageProofDepositOne() public pure returns (bytes[] memory storageProofArr) {
        storageProofArr = new bytes[](3);

        storageProofArr[0] =
            hex"f87180808080a03c92b61d416e91dc69fa87dd4b52ae3e4229fa2d7be76cc9b6173c04b9f938948080a03d330cbe29881fcb0d06f42ef7c73bffaacf45fe22c2e94560d0cb18a61ff37a808080a0f4984a11f61a2921456141df88de6e1a710d28681b91af794c5a721e47839cd78080808080";
        storageProofArr[1] =
            hex"f851a0ad42e1edb0c73638954137aa6a8b81f68c8bb79b345826de7aa15c82de29bee080808080808080808080a0c7e8c82df0b4d6ed871ccd192478e2ff8030136cad665cc7ab6fdc8c146859b98080808080";
        storageProofArr[2] =
            hex"f843a020f25e97012c20910400e86321fb6bc8bb83c6ffb146881d997cbad075087089a1a05858edf174ac03f9c53790ca8545f827eb3cc142106ae17bebf6f01551bc1656";
    }

    function storageProofInvalidDeposit() public pure returns (bytes[] memory storageProofArr) {
        storageProofArr = new bytes[](2);

        storageProofArr[0] =
            hex"f87180808080a03c92b61d416e91dc69fa87dd4b52ae3e4229fa2d7be76cc9b6173c04b9f938948080a03d330cbe29881fcb0d06f42ef7c73bffaacf45fe22c2e94560d0cb18a61ff37a808080a0f4984a11f61a2921456141df88de6e1a710d28681b91af794c5a721e47839cd78080808080";
        storageProofArr[1] =
            hex"f843a033524159aecef2c48536ead2e14ada747cbcc5edb9e69bed129c51895085f8efa1a0a4991c98fb3cffdd001a1ac90467fb0a3417c9032762ab3d717fbf955780b39e";
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
        invalidDeposit.srcChainId = 1;
        invalidDeposit.dstChainId = 2;
        invalidDeposit.from = defaultSender;
        invalidDeposit.to = defaultSender;
        invalidDeposit.amount = depositAmount;
        invalidDeposit.data = "";

        vm.selectFork(L1Fork);
        bool storedInGenericNamespace =
            L1signalService.isSignalStored(invalidDepositId, L1ChainId, defaultSender, keccak256("generic-signal"));
        assertTrue(storedInGenericNamespace);

        bool storedInEthBridgeNamespace =
            L1signalService.isSignalStored(invalidDepositId, L1ChainId, defaultSender, keccak256("eth-bridge"));
        assertFalse(storedInEthBridgeNamespace);

        vm.selectFork(L2Fork);
        // to be extra sure its not a problem with the proof
        L2signalService.verifySignal(L1ChainId, commitmentHeight, defaultSender, invalidDepositId, encodedProof);

        // I believe this error means that the proof is not valid for this deposit id
        vm.expectRevert("MerkleTrie: invalid large internal hash");
        L2signalService.claimDeposit(invalidDeposit, commitmentHeight, encodedProof);
    }
}
