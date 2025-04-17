// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {ISignalService} from "src/protocol/ISignalService.sol";
import {SignalService} from "src/protocol/SignalService.sol";

import {MockAnchor} from "test/mocks/MockAnchor.sol";
import {MockCheckpointTracker} from "test/mocks/MockCheckpointTracker.sol";

/// @notice These tests are simulating cross-chain signaling between L1 and L2.
/// They use fork testing to simulate L1 and L2 chains. You must therefore run the tests
/// with two anvil nodes running in the background. One on port 8545 (L1) and one on port 8546 (L2).
/// command to run anvil:
/// just start-anvil
/// These tests will not run if BOTH anvil nodes are not running.

/// State where there are no signals.
contract BaseState is Test {
    SignalService public L1signalService;
    SignalService public L2signalService;
    MockCheckpointTracker public checkpointTracker;
    MockAnchor public anchor;

    uint256 public L1Fork;
    uint256 public L2Fork;
    // this is set in the just file
    uint256 public L1ChainId = 1;
    uint256 public L2ChainId = 2;

    // public key: 0xCf03Dd0a894Ef79CB5b601A43C4b25E3Ae4c67eD
    address public rollupOperator = vm.addr(0x1234);

    // Default sender is account[0] of an anvil node
    // This is needed to get deterministic addresses for the contracts that match
    // the storage proofs generated in offchain/signal_proofs.rs
    // BUG: For some reason the default sender is not being changed even though
    // it's is the foundry.toml file, therefore we need to set it manually
    // make sure all signals are sent from this sender
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

        vm.prank(defaultSender);
        L1signalService = new SignalService(rollupOperator);
        vm.deal(address(L1signalService), ETHBridgeInitBalance);

        checkpointTracker = new MockCheckpointTracker(address(L1signalService));

        L2Fork = vm.createFork("L2");
        vm.selectFork(L2Fork);

        // Sender has 0 eth in the L2 fork
        vm.deal(defaultSender, senderBalanceL2);

        vm.prank(defaultSender);
        L2signalService = new SignalService(rollupOperator);
        vm.deal(address(L2signalService), ETHBridgeInitBalance);

        anchor = new MockAnchor(address(L2signalService));

        vm.prank(rollupOperator);
        L2signalService.setAuthorizedCommitter(address(anchor));

        // Labels for debugging
        vm.label(address(L1signalService), "L1signalService");
        vm.label(address(L2signalService), "L2signalService");
        vm.label(address(checkpointTracker), "CheckpointTracker");
        vm.label(address(anchor), "MockAnchor");
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

    bytes32 public stateRoot = hex"c1e08570f2f86772aa068d2e6c1472882937999e45024cb2b1eb4695aecb954a";
    bytes32 public storageRoot = hex"fe201dc3c31cfab4e0f804fa77b26ee77eb433cafdc4a457081e12a1fb77321f";

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(L1Fork);
        vm.prank(defaultSender);
        L1signalService.sendSignal(signal);
    }

    // NOTE: This proof is only valid for the given stateRoot and storageRoot
    function accountProof() public pure returns (bytes[] memory accountProofArr) {
        accountProofArr = new bytes[](3);

        accountProofArr[0] =
            hex"f90131a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0ca0af0336a19f157e2f616a5b7557ba54812e9ad3a58b56779586bdbb5f80730a080280f69e5744940c0036bf54b8e0cf3fbadaaa171a03d40ad200be2c26c6a478080a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0c67cf1b037ce86bf013a67a6303a5036c3bc8144c2efa48cdde44085d8dfb205a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProofArr[1] =
            hex"f85180808080a01d4fc1db150c495ea949963e88a103a93033d24d54c6166363794291d9fda8c780808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProofArr[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0fe201dc3c31cfab4e0f804fa77b26ee77eb433cafdc4a457081e12a1fb77321fa0ddfe133f8d0695ac1f20fc88dcdc608589d64d03d20e948e7486d381b9e2c426";
    }

    // NOTE: This proof is only valid for the defaultSender address and signal
    // For the given stateRoot and storageRoot
    function storageProof() public pure returns (bytes[] memory storageProofArr) {
        storageProofArr = new bytes[](2);

        storageProofArr[0] =
            hex"f85180808080a015ae32d5986f7e597e8a4db519e6640db0eeb8271f30c7691dc58cd99b9cae8d808080808080a09e55e2648102fda81eb95b4ee10aee84628a953d4878b0f6a4d0736614d94a168080808080";
        storageProofArr[1] =
            hex"f843a034f6405d43a092e4cd9a4c9c942b759fef6afe35152e7dff7baf6f0c82cd54e2a1a029d86d891992a0a891ff8cc9477d178707448d6a8f2f8a15fe1ca735238569e4";
    }
}

contract SendL1SignalTest is SendL1SignalState {
    function test_verifyL1Signal_UsingBothProofs() public {
        vm.selectFork(L2Fork);

        ISignalService.SignalProof memory signalProof = ISignalService.SignalProof(accountProof(), storageProof());
        bytes memory encodedProof = abi.encode(signalProof);

        uint256 height = 1;
        anchor.anchor(height, stateRoot);

        L2signalService.verifySignal(L1ChainId, height, defaultSender, signal, encodedProof);
    }

    function test_verifyL1Signal_UsingStorageProof() public {
        vm.selectFork(L2Fork);

        bytes[] memory accountProof = new bytes[](0);
        ISignalService.SignalProof memory signalProof = ISignalService.SignalProof(accountProof, storageProof());
        bytes memory encodedProof = abi.encode(signalProof);

        uint256 height = 1;
        anchor.anchor(height, storageRoot);

        L2signalService.verifySignal(L1ChainId, height, defaultSender, signal, encodedProof);
    }
}
