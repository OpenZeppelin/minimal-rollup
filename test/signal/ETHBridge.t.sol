// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {BaseState} from "./SignalService.t.sol";

import {ETHBridge} from "src/protocol/ETHBridge.sol";

import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

// represents state where a deposit is made on L1
// however, the it is not yet available on L2
contract BridgeETHState is BaseState {
    // 0xf9c183d2de58fbeb1a8917170139e980fa1b6e5a358ec83721e11c9f6e25eb18
    bytes32 public depositIdOne;
    uint256 public depositAmount = 4 ether;
    ETHBridge.ETHDeposit public depositOne;

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(L1Fork);

        vm.prank(defaultSender);
        bytes memory emptyData = "";
        vm.recordLogs();
        depositIdOne = L1signalService.deposit{value: depositAmount}(defaultSender, emptyData);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        depositOne = abi.decode(entries[0].data, (IETHBridge.ETHDeposit));
        console.logBytes32(depositIdOne);
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
    bytes32 public stateRoot = hex"fbe8cce9a9b7d6fd0bb98caf75ba1b45599b50ff8c580410295c0718bfe47efa";
    bytes32 public storageRoot = hex"fa81d0fcbc4760c6257aa0af8c8af971d303c05ef7a7560bc5688cd6f1830202";
    uint256 public commimentHeight = 1;

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(L2Fork);
        anchor.anchor(commimentHeight, stateRoot);
    }

    // NOTE: This proof is only valid for the defaultSender address and depositIDOne
    // For the given stateRoot and storageRoot
    function storageProofDepositOne() public pure returns (bytes[] memory storageProofArr) {
        storageProofArr = new bytes[](2);
        storageProofArr[0] =
            hex"f87180808080a015ae32d5986f7e597e8a4db519e6640db0eeb8271f30c7691dc58cd99b9cae8d808080808080a0f4984a11f61a2921456141df88de6e1a710d28681b91af794c5a721e47839cd780a060be43426df604212322c09fe9045ffb7543b0bcd0f927cd90fed17ea5057912808080";
        storageProofArr[1] =
            hex"f843a03e489ae456a515de885d39c5188bcd6169574db5667aa9ba76cfe7c1e9afc5fea1a0f9c183d2de58fbeb1a8917170139e980fa1b6e5a358ec83721e11c9f6e25eb18";
    }

    // NOTE: This proof is only valid for the defaultSender address and depositIDOne
    // For the given stateRoot and storageRoot
    function accountProofDepositOne() public pure returns (bytes[] memory accountProofArr) {
        accountProofArr = new bytes[](3);
        accountProofArr[0] =
            hex"f90131a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0d488af79096a2964cb04880ba9096e6377def776e644fa1b270621f48d18ffbca0e3a93829cd09eb3909a423afe24c8e6b550972db00c48860ade430c0bc09987c8080a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0fb976cc6df6005ebc8731b68fca2e247462644bf69e3c89c8f4446e0f276d33aa0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProofArr[1] =
            hex"f85180808080a00ceaa69016e6a6540bb59b4dc3ea040cddc07e27d18add61a313cd3ef748a58680808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProofArr[2] =
            hex"f871a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb84ef84c01883782dace9d900000a0fa81d0fcbc4760c6257aa0af8c8af971d303c05ef7a7560bc5688cd6f1830202a082b5a68e8d4087a7132e9f24fa54d04cc635bec5a6e773152eac141eeff8309d";
    }
}

contract ClaimDepositTest is CommitmentStoredState {
    function test_claimDeposit() public {
        vm.selectFork(L2Fork);

        bytes[] memory accountProof = accountProofDepositOne();
        bytes[] memory storageProof = storageProofDepositOne();
        ISignalService.SignalProof memory signalProof = ISignalService.SignalProof(accountProof, storageProof);
        bytes memory encodedProof = abi.encode(signalProof);

        L2signalService.claimDeposit(depositOne, commimentHeight, encodedProof);

        assertEq(address(L2signalService).balance, ETHBridgeInitBalance - depositAmount);
        assertEq(defaultSender.balance, senderBalanceL2 + depositAmount);
    }
}
