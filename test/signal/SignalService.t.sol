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
    SignalService public L1signalService;
    SignalService public L2signalService;
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

    bytes32 public stateRoot = hex"c2fc76c98cf1fcaaa5c09f1cb7037dda22c40875fe735047b7ef7f0af85e38af";
    bytes32 public storageRoot = hex"f01c88ce7264fe74660609ef1d5d438999d7ef18f1d88ed249d1d7d7a8e94d18";

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(L1Fork);
        vm.prank(defaultSender);
        L1signalService.sendSignal(signal);
    }

    // NOTE: This proof is only valid for the defaultSender address and signal
    // For the given stateRoot and storageRoot
    function storageProof() public pure returns (bytes[] memory storageProofArr) {
        storageProofArr = new bytes[](2);

        storageProofArr[0] =
            hex"f851a080baad112bc5a4268d8dd59ff76d5b88e71e2b520901d30d326a96a76903bc53808080a015ae32d5986f7e597e8a4db519e6640db0eeb8271f30c7691dc58cd99b9cae8d808080808080808080808080";
        storageProofArr[1] =
            hex"f843a032fbc053d21d1450a7eb877000b701317b2bf5fa5907266fb096a14feb00db21a1a0e321d900f3fd366734e2d071e30949ded20c27fd638f1a059390091c643b62c5";
    }

    // NOTE: This proof is only valid for the defaultSender address and signal
    // For the given stateRoot and storageRoot
    function accountProof() public pure returns (bytes[] memory accountProofArr) {
        accountProofArr = new bytes[](3);
        accountProofArr[0] =
            hex"f90131a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0a317b57ebdf1ed132de2a0f20cda7fd7bc1d03a95e4e1184ae686dadcf2be256a07a7a095f6953f80d64ccaf28ce648fc835f4a13d3917bc9ce35f2bc031f1e42d8080a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a049b32a5498c101056185de075aac7b4103c2c8fd8103346174ce7350d91f3f69a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProofArr[1] =
            hex"f85180808080a00ec1d6386e1fd33787349326bafae738ddca2f7675207cdcd58d14acaca6b14080808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProofArr[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0f01c88ce7264fe74660609ef1d5d438999d7ef18f1d88ed249d1d7d7a8e94d18a0c3383e222528fd1d715f60818351e1eb07a7908d895d402b584bba66035142d5";
    }
}

contract SendL1SignalTest is SendL1SignalState {
    function test_verifyL1Signal_UsingBothProofs() public {
        vm.selectFork(L2Fork);

        ISignalService.SignalProof memory signalProof = ISignalService.SignalProof(accountProof(), storageProof());
        bytes memory encodedProof = abi.encode(signalProof);

        uint256 height = 1;
        anchor.anchor(height, stateRoot);

        L2signalService.verifySignal(height, defaultSender, signal, encodedProof);
    }

    function test_verifyL1Signal_UsingStorageProof() public {
        vm.selectFork(L2Fork);

        bytes[] memory accountProof = new bytes[](0);
        ISignalService.SignalProof memory signalProof = ISignalService.SignalProof(accountProof, storageProof());
        bytes memory encodedProof = abi.encode(signalProof);

        uint256 height = 1;
        anchor.anchor(height, storageRoot);

        L2signalService.verifySignal(height, defaultSender, signal, encodedProof);
    }
}
