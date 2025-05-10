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
    ETHBridge public L1EthBridge;
    // We need to pass the address of each bridge to the constructor of its counterpart
    // This can be achieved with create2 or with proxy deployments
    // For testing, we place the L2EthBridge at a specific address
    ETHBridge public L2EthBridge = ETHBridge(address(uint160(uint256(keccak256("L2EthBridge")))));

    // 0xf9c183d2de58fbeb1a8917170139e980fa1b6e5a358ec83721e11c9f6e25eb18
    bytes32 public depositIdOne;
    uint256 public depositAmount = 4 ether;
    ETHBridge.ETHDeposit public depositOne;

    // ETHBridge which has a large amount of ETH
    uint256 public ETHBridgeInitBalance = 100 ether;

    uint256 public senderBalanceL1 = 10 ether;
    uint256 public senderBalanceL2 = 0 ether;

    function setUp() public virtual override {
        super.setUp();

        vm.selectFork(L1Fork);
        // Deploy L1EthBridge
        vm.setNonce(defaultSender, 2);
        vm.prank(defaultSender);
        L1EthBridge = new ETHBridge(address(L1SignalService), address(checkpointTracker), address(L2EthBridge));
        vm.deal(address(L1EthBridge), ETHBridgeInitBalance);

        vm.prank(defaultSender);
        vm.deal(defaultSender, senderBalanceL1);
        bytes memory emptyData = "";
        depositIdOne = L1EthBridge.deposit{value: depositAmount}(defaultSender, emptyData);
    }
}

// Need to separate the states or it crashes
contract BridgeETHState2 is BridgeETHState {
    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(L2Fork);
        vm.deal(defaultSender, senderBalanceL2);
        // Deploy L2EthBridge
        vm.setNonce(defaultSender, 2);
        vm.prank(defaultSender);
        deployCodeTo(
            "ETHBridge.sol",
            abi.encode(address(L2SignalService), address(anchor), address(L1EthBridge)),
            address(L2EthBridge)
        );
        vm.deal(address(L2EthBridge), ETHBridgeInitBalance);
    }
}

contract ETHBridgeTest is BridgeETHState2 {
    function test_initialDepositState() public {
        vm.selectFork(L1Fork);
        assertEq(address(L1EthBridge).balance, ETHBridgeInitBalance + depositAmount);
        assertEq(defaultSender.balance, senderBalanceL1 - depositAmount);

        vm.selectFork(L2Fork);
        assertEq(L2EthBridge.claimed(depositIdOne), false);
        assertEq(defaultSender.balance, senderBalanceL2);
    }
}

contract CommitmentStoredState is BridgeETHState {
    bytes32 public stateRoot = hex"b56827bea299e8ea13277172f0839722368039e3acf7e1a44048a76f783fbcd5";
    uint256 public commitmentHeight = 1;

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(L2Fork);
        anchor.anchor(commitmentHeight, stateRoot);
    }

    function accountProofSignalService() public pure returns (bytes[] memory accountProofArr) {
        accountProofArr = new bytes[](3);
        accountProofArr[0] =
            hex"f90131a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02d4083d5d0f8156ad256d9234d424cd9e49fb1812d743e9c734b4f414e505e63a078cd190fd2ca48935f923419a47d2857d520e451bbf7d51be5c77d672f9c5cd08080a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0b1deafb10e860851c54e860bf8247c81cc05c0d19ed742f144b4fcca3be5e121a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProofArr[1] =
            hex"f85180808080a090e25787e679147069a9022e76f57949e7ec57d5368ec66212e165f83ff5ff8680808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProofArr[2] =
            hex"f871a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb84ef84c01883782dace9d900000a0584ab30fb9214d0f4b747d87b177802f7022e18ec5ed2c58a85e3bfa953915d0a0c0ba2d0c0eedb3a5fcd78a0aa384e2399651f191eccdd9576bec86c1c300607f";
    }

    function storageProofDepositOne() public pure returns (bytes[] memory storageProofArr) {
        storageProofArr = new bytes[](2);
        storageProofArr[0] =
            hex"f89180808080a015ae32d5986f7e597e8a4db519e6640db0eeb8271f30c7691dc58cd99b9cae8da0189ef9b745baf1cac397de18cd0daa0080adc277514b3424e51add1fa0560caa8080808080a0f4984a11f61a2921456141df88de6e1a710d28681b91af794c5a721e47839cd780a07922f462ebc1e5dbf5d9cf69804cfb38646a24cce553010811b89d913f1e0544808080";
        storageProofArr[1] =
            hex"f843a03e489ae456a515de885d39c5188bcd6169574db5667aa9ba76cfe7c1e9afc5fea1a01731af609b4a0951d3773ff202fa03d48b0d9db4630773c1330747c674c86ea1";
    }
}

contract ClaimDepositTest is CommitmentStoredState {
    function test_claimDeposit() public {
        bytes[] memory accountProof = accountProofSignalService();
        bytes[] memory storageProof = storageProofDepositOne();
        ISignalService.SignalProof memory signalProof = ISignalService.SignalProof(accountProof, storageProof);
        bytes memory encodedProof = abi.encode(signalProof);

        IETHBridge.ETHDeposit memory depositOne =
            IETHBridge.ETHDeposit(0, defaultSender, defaultSender, depositAmount, bytes(""));

        vm.selectFork(L2Fork);
        L2EthBridge.claimDeposit(depositOne, commitmentHeight, encodedProof);
        // assertEq(address(L2EthBridge).balance, ETHBridgeInitBalance - depositAmount);
        // assertEq(defaultSender.balance, senderBalanceL2 + depositAmount);
    }
}
