// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// This file is auto-generated with the command `just get-sample-deposit-proof`.
// Do not edit manually.
// See ISampleDepositProof.t.sol for an explanation of its purpose.

import {ISampleDepositProof} from "./ISampleDepositProof.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

contract SampleDepositProof is ISampleDepositProof {
    /// @inheritdoc ISampleDepositProof
    function getSourceAddresses() public pure returns (address signalService, address bridge) {
        signalService = address(0x5FbDB2315678afecb367f032d93F642f64180aa3);
        bridge = address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
    }

    /// @inheritdoc ISampleDepositProof
    function getDepositSignalProof() public pure returns (ISignalService.SignalProof memory signalProof) {
        signalProof = ISignalService.SignalProof({
            accountProof: new bytes[](3),
            storageProof: new bytes[](1),
            stateRoot: bytes32(0xe0a07ba336908550313d032fdd19671e71cb641137f060b659efd4392deb21f3),
            blockHash: bytes32(0xe7ba7bd1d55f03198432163104a7589ce32544c1c691566369dc01544bf5ffb3)
        });

        signalProof.accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0ee4474f2689549941b15b3843a811a782cb08d47eeb6e7e52fe8c1b4429706a1a07b9b5af76aaacfe822062ed002c6db0b494ae66b9dbe3e91c7c398088a92090480a018a8ad351982e9ff9296e1622bf1ef1fa50e27b9a31560b28a69c1591a8a0deba04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0135821bc0f581df8c3f1e24931a7b6fdb30bccc34ba47efa2bfb4c28738b1b83a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        signalProof.accountProof[1] =
            hex"f85180808080a0fd24b3e5c9542e48f4cafa4d9c88293a8c9f8a33e921e7a998f5cd043e85aa3180808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        signalProof.accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0ce1466d882d594fe9e8cefe5a31da897d58265ec827a10dc5ecefcf25b71f061a0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";

        signalProof.storageProof[0] = hex"e3a120077b99d702aa11c12c9288f20fa44c3b0580a5d093a01c3b147a75e576c2acd301";
    }

    /// @inheritdoc ISampleDepositProof
    function getEthDeposit() public pure returns (IETHBridge.ETHDeposit memory deposit) {
        deposit = IETHBridge.ETHDeposit({
            nonce: 0,
            from: address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266),
            to: address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa),
            amount: 0,
            data: bytes("")
        });
    }

    /// @inheritdoc ISampleDepositProof
    function getDepositInternals() public pure returns (bytes32 slot, bytes32 id) {
        slot = bytes32(0x68a23db59bedfe3ee7741e80394f17cf48ea56a779b95ee41a87441bfbcbb800);
        id = bytes32(0xe6b3813ebb86846581f31ebfc306df9e9b419c7c618c87135fae88ee6f5caf7e);
    }
}
