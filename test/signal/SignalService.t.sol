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

    function setUp() public virtual {
        L1Fork = vm.createFork("L1");
        vm.selectFork(L1Fork);

        // Deploy L1SignalService
        vm.prank(defaultSender);
        L1SignalService = new SignalService();
        vm.label(address(L1SignalService), "L1SignalService");

        checkpointTracker = new MockCheckpointTracker(address(L1SignalService));

        L2Fork = vm.createFork("L2");
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

    bytes32 public blockHash = 0x72ea63fa1980ed28a3e10245096d3bb7c717d83e025bcfb6e0a2889fa88984c7;
    bytes32 public stateRoot = 0xbea626defff8745e6a6fd162f3480615a0e6eb285b8a8ba54b31fe2ffa950874;
    bytes32 public storageRoot = 0x04bdf08088bbf36329fe89a42e20579b0a9222b2301b4787eeecc03ef88bc507;

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
            hex"f90131a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0fef0c7c87dc696c2c46d604ce29ffaf22a6d8d5dd27a870bf7a1e5876ca1fb54a0020661ea7d89845cd171e352778b18641eff9efb62028c299df4151e24f5fb118080a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0ec044885b8e2bda68bf3d4f74c7fb65a5f486e8e28f60779434e8665d673e462a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProofArr[1] =
            hex"f85180808080a0428f207aafab0fd01965cc7f77e3384ea7a4d8394fed11ebfd61af33c1f8edbc80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProofArr[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a004bdf08088bbf36329fe89a42e20579b0a9222b2301b4787eeecc03ef88bc507a01888e1db1505f5e9b5fe0dc6dbe14a7be2f812e4de535528fe243e01a49e8b65";
    }
}

contract SendL1SignalTest is SendL1SignalState {
    function test_verifyL1Signal_UsingBothProofs() public {
        vm.selectFork(L1Fork);
        bool isSignalStored = L1SignalService.isSignalStored(signal, defaultSender);
        assertTrue(isSignalStored);

        vm.selectFork(L2Fork);

        ISignalService.SignalProof memory signalProof =
            ISignalService.SignalProof(accountProof(), storageProof(), stateRoot, blockHash);
        bytes memory encodedProof = abi.encode(signalProof);

        uint256 height = 1;
        bytes32 commitment = keccak256(abi.encode(stateRoot, blockHash));
        anchor.anchor(height, commitment);

        L2SignalService.verifySignal(height, address(anchor), defaultSender, signal, encodedProof);
    }
}
