// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {ISignalService} from "src/protocol/ISignalService.sol";
import {SignalService} from "src/protocol/SignalService.sol";

import {MockAnchor} from "test/mocks/MockAnchor.sol";
import {MockCheckpointTracker} from "test/mocks/MockCheckpointTracker.sol";

/// State where there are no signals.
contract BaseState is Test {
    SignalService L1signalService;
    SignalService L2signalService;
    MockCheckpointTracker checkpointTracker;
    MockAnchor anchor;

    address public rollupOperator = vm.addr(0x1234);
    address sender = vm.addr(0x2222);

    function setUp() public virtual {
        console.log("msg.sender", msg.sender);
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        L1signalService = new SignalService(rollupOperator);
        L2signalService = new SignalService(rollupOperator);

        vm.label(address(L1signalService), "L1signalService");
        vm.label(address(L2signalService), "L2signalService");

        checkpointTracker = new MockCheckpointTracker(address(L1signalService));
        vm.label(address(checkpointTracker), "CheckpointTracker");

        anchor = new MockAnchor(address(L2signalService));
        vm.label(address(anchor), "MockAnchor");
        vm.prank(rollupOperator);
        L2signalService.setAuthorizedCommitter(address(anchor));
    }
}

contract SendL1SignalState is BaseState {
    uint256 public value = 0x1234;

    function setUp() public virtual override {
        super.setUp();
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        L1signalService.sendSignal(keccak256(abi.encode(value)));
    }
}

contract SendL1SignalTest is SendL1SignalState {
    function test_sendL1Signal() public {
        vm.skip(true);
        bytes[] memory storageProof = new bytes[](2);
        storageProof[0] =
            "0xf85180808080a015ae32d5986f7e597e8a4db519e6640db0eeb8271f30c7691dc58cd99b9cae8d80a0a160b00940ca7a9c5095328a15b5db8f3df8a2fb5044c2a1d68881196bc70e1580808080808080808080";
        storageProof[1] =
            "0xf843a0354ada5ea82feea206d357f61e2debe1375f3ba29fb1583a75918c3e84924563a1a0e321d900f3fd366734e2d071e30949ded20c27fd638f1a059390091c643b62c5";

        bytes[] memory accountProof = new bytes[](3);
        accountProof[0] =
            "0xf90131a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0942e72a5b080bd98bb9d56695a657199569dcc880dda8821da899e675cba2c0aa082c69113880d067bc0ec1367caa94b507265709ad98db5915d44b93a6e31cc038080a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0b24ef8583930c8b8dafe2500b23633c2d1bc4d49d4d75f92d6d1bbe53ddfafd7a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            "0xf85180808080a06c4166f9b5f3628a3af12051a3ecfe8a16355d372e20fbcaf6a8e751c418042580808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            "0xf869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a04112cb836908f39193de897177c47c54194a033116b0757b309946d9e456be3ba03aa3f6fb42cd14c9a6c68e36728dfa67f5a6eb85e617e6f97be87baab3ecbb3a";

        ISignalService.SignalProof memory signalProof = ISignalService.SignalProof(accountProof, storageProof);
        anchor.anchor(1, 0x78d2e23c96c90d06cd025f34fabf1467095ca52fb85077460655c23df846a474);
        L2signalService.verifySignal(
            1, 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, keccak256(abi.encode(value)), abi.encode(signalProof)
        );
    }
}
