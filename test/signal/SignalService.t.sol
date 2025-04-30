// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {ISignalService} from "src/protocol/ISignalService.sol";
import {SignalService} from "src/protocol/SignalService.sol";

import {MockAnchor} from "test/mocks/MockAnchor.sol";
import {MockCheckpointTracker} from "test/mocks/MockCheckpointTracker.sol";

/// @notice These tessts are simulating cross-chain signaling between L1 and L2.
/// They use fork testing to simulate L1 and L2 chains. You must therefore run the tests
/// with two anvil nodes running in the background. One on port 8545 (L1) and one on port 8546 (L2).
/// command to run anvil:
/// just start-anvil
/// These tests will not run if BOTH anvil nodes are not running.

/// State where there are no signals.
contract BaseState is Test {
    SignalService public L1SignalService;
    SignalService public L2SignalService;

    MockCheckpointTracker public checkpointTracker;
    MockAnchor public anchor;

    uint256 public L1Fork;
    uint256 public L2Fork;

    // public key: 0xCf03Dd0a894Ef79CB5b601A43C4b25E3Ae4c67eD
    address public rollupOperator = vm.addr(0x1234);

    // Default sender is account[0] of an anvil node
    // This is needed to get deterministic addresses for the contracts that match
    // the storage proofs generated in offchain/signal_proofs.rs
    // BUG: For some reason the default sender is not being changed even though
    // it's is the foundry.toml file, therefore we need to set it manually
    address public defaultSender = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    uint256 public senderBalanceL1 = 10 ether;
    uint256 public senderBalanceL2 = 0 ether;

    // Signal service is also the ETHBridge which has a large amount of ETH
    uint256 public ETHBridgeInitBalance = 100 ether;

    function setUp() public virtual {
        L1Fork = vm.createFork("L1");
        vm.selectFork(L1Fork);
        // Sender has 10 eth in the L1 fork
        vm.deal(defaultSender, senderBalanceL1);

        // Deploy L1SignalService
        vm.prank(defaultSender);
        L1SignalService = new SignalService();
        vm.label(address(L1SignalService), "L1SignalService");

        checkpointTracker = new MockCheckpointTracker(address(L1SignalService));

        L2Fork = vm.createFork("L2");

        // Sender has 0 eth in the L2 fork
        vm.deal(defaultSender, senderBalanceL2);

        vm.selectFork(L2Fork);

        // Deploy L2SignalService
        vm.prank(defaultSender);
        L2SignalService = new SignalService();
        vm.label(address(L2SignalService), "L2SignalService");

        // Deploy MockAnchor
        anchor = new MockAnchor(address(L2SignalService));
    }
}

/// @dev To generate new values for the proofs and associated state roots
/// run the following command:
/// just get-signal-proofs sender signal
/// The sender is whoever is sending the signal, in this case the defaultSender
/// The signal is the value that is being sent, in this case keccak256(abi.encode(0x1234));
///
/// State where an arbitrary signal is sent from L1 to L2.
contract SendL1SignalState is BaseState {
    uint256 public value = 0x1234;
    // 0xe321d900f3fd366734e2d071e30949ded20c27fd638f1a059390091c643b62c5
    bytes32 public signal = keccak256(abi.encode(value));

    bytes32 public stateRoot = hex"afeb12112708b753dee82f80647b152125d8d31c9d58cd6eb5b55c80f130bcfd";
    bytes32 public storageRoot = hex"04bdf08088bbf36329fe89a42e20579b0a9222b2301b4787eeecc03ef88bc507";

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(L1Fork);
        vm.prank(defaultSender);
        L1SignalService.sendSignal(signal);
    }

    // NOTE: This proof is only valid for the defaultSender address and signal
    // For the given stateRoot and storageRoot
    function storageProof() public pure returns (bytes[] memory storageProofArr) {
        storageProofArr = new bytes[](1);
        storageProofArr[0] = hex"e3a120b85a01aaebad61d59b54ccfbfab9d3934481964f6208167ef0868494605ddc8401";
    }

    // NOTE: This proof is only valid for the given stateRoot and storageRoot
    function accountProof() public pure returns (bytes[] memory accountProofArr) {
        accountProofArr = new bytes[](3);

        accountProofArr[0] =
            hex"f90131a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0089013914176be36b11c71ff3b8a136c0a47bcf74b4ef922567c19d36814a4c7a09491a0bc16e49dd46059e35bdafadbd765d8daa1b1088151eee07161124824a28080a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0bbe068d0fb4ae57d0a82da1469f15383b562d29d001e7bd9693b0e5fd1b5e998a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProofArr[1] =
            hex"f85180808080a000b85deecd2beb8cead803f57b060d758bd1a3109255e2e8b7c120d08dd06c3f80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProofArr[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a004bdf08088bbf36329fe89a42e20579b0a9222b2301b4787eeecc03ef88bc507a0c39e34a085b4c4074cb6f667a85c9d06b08fb97dcde27b211f9cd0648028fb84";
    }
}

contract SendL1SignalTest is SendL1SignalState {
    function test_verifyL1Signal_UsingBothProofs() public {
        vm.selectFork(L1Fork);
        bool isSignalStored = L1SignalService.isSignalStored(signal, defaultSender);
        assertTrue(isSignalStored);

        vm.selectFork(L2Fork);

        ISignalService.SignalProof memory signalProof = ISignalService.SignalProof(accountProof(), storageProof());
        bytes memory encodedProof = abi.encode(signalProof);

        uint256 height = 1;
        anchor.anchor(height, stateRoot);

        L2SignalService.verifySignal(height, address(anchor), defaultSender, signal, encodedProof);
    }
}
