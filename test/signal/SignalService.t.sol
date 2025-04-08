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
/// anvil --port 8545
/// anvil --port 8546
/// These tests will not run if BOTH anvil nodes are not running.

/// State where there are no signals.
contract BaseState is Test {
    SignalService L1signalService;
    SignalService L2signalService;
    MockCheckpointTracker checkpointTracker;
    MockAnchor anchor;

    uint256 public L1Fork;
    uint256 public L2Fork;

    address public rollupOperator = vm.addr(0x1234);
    // Default sender is account[0] of an anvil node
    // This is needed to get deterministic addresses for the contracts that match
    // the storage proofs generated in scripts/generate_signal_proofs.sh
    address defaultSender = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    function setUp() public virtual {
        L1Fork = vm.createFork("L1");
        vm.selectFork(L1Fork);

        vm.prank(defaultSender);
        L1signalService = new SignalService(rollupOperator);
        checkpointTracker = new MockCheckpointTracker(address(L1signalService));

        L2Fork = vm.createFork("L2");
        vm.selectFork(L2Fork);
        vm.prank(defaultSender);
        L2signalService = new SignalService(rollupOperator);
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

// State where a signal is sent from L1 to L2.
contract SendL1SignalState is BaseState {
    uint256 public value = 0x1234;
    // 0xe321d900f3fd366734e2d071e30949ded20c27fd638f1a059390091c643b62c5
    bytes32 public signal = keccak256(abi.encode(value));
    bytes32 public stateRoot = hex"863fb52dc6f4397decb2baaf29af5abf224c675e08ade3623eaf050ac418ee97";

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(L1Fork);
        vm.prank(defaultSender);
        L1signalService.sendSignal(signal);
    }

    function getStorageProof() public pure returns (bytes[] memory) {
        bytes[] memory storageProof = new bytes[](2);
        storageProof[0] =
            hex"f85180808080a015ae32d5986f7e597e8a4db519e6640db0eeb8271f30c7691dc58cd99b9cae8d80a0a160b00940ca7a9c5095328a15b5db8f3df8a2fb5044c2a1d68881196bc70e1580808080808080808080";
        storageProof[1] =
            hex"f843a0354ada5ea82feea206d357f61e2debe1375f3ba29fb1583a75918c3e84924563a1a0e321d900f3fd366734e2d071e30949ded20c27fd638f1a059390091c643b62c5";
        return storageProof;
    }

    function getAccountProof() public pure returns (bytes[] memory) {
        bytes[] memory accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90131a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a04cf95904de6a2222b1265db3c873bc09af47912a53b6f57175fddf2b88a8ffeda099cbe53f7954cea6840ce5238045f5294683729e85deec11239e06e6efe12be38080a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a043c8932ac56008879d2f5035d5ee33ba20eeebba97608c62e281dbbbe00d3535a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a00400ea56bf7704ba7dcd741a5d7aaf0967fc83e0483f106d100b416760c7d7fd80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a04112cb836908f39193de897177c47c54194a033116b0757b309946d9e456be3ba034dcb5cc12f11a1ef743726b67363c08156d996968139cf2254c04b7a49eadc7";
        return accountProof;
    }
}

contract SendL1SignalTest is SendL1SignalState {
    function test_sendL1Signal() public {
        vm.selectFork(L2Fork);
        ISignalService.SignalProof memory signalProof = ISignalService.SignalProof(getAccountProof(), getStorageProof());
        bytes memory encodedProof = abi.encode(signalProof);
        uint256 height = 1;
        anchor.anchor(height, stateRoot);
        L2signalService.verifySignal(height, defaultSender, signal, encodedProof);
    }
}
