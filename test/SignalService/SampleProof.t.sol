// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// This file is auto-generated with the command `just get-sample-signal-proof`.
// Do not edit manually.
// See ISampleProof.t.sol for an explanation of its purpose.

import {ISampleProof} from "./ISampleProof.t.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

contract SampleProof is ISampleProof {
    /// @inheritdoc ISampleProof
    function getSignalServiceAddress() public pure returns (address) {
        return address(0x5FbDB2315678afecb367f032d93F642f64180aa3);
    }

    /// @inheritdoc ISampleProof
    function getSignalProof() public pure returns (ISignalService.SignalProof memory signalProof) {
        signalProof = ISignalService.SignalProof({
            accountProof: new bytes[](3),
            storageProof: new bytes[](1),
            stateRoot: bytes32(0xa5d8725608e3d53dd7af5cad105ee1ff73a476255cb488d8ac7a19380618fae7),
            blockHash: bytes32(0x6efd818b4ad28d44f1a95dfd558fd407656ca2f5b57973f692b16486f14ef8fa)
        });

        signalProof.accountProof[0] =
            hex"f90131a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a015b03aaf615a8c4fe56b96ecbb199a755d5de56f770648d8c1f10cd4673d4817a0533540b3b96b2a8549d5f7bfe3ad0100d9d3cf1df14daef68805e868255d626f8080a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a04a8e98403c548519920cfc70c3e938c753b79e4c4ec8659fe7cd34fbb1f06b3da0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        signalProof.accountProof[1] =
            hex"f85180808080a0cee4f950aa1b1110d20dc6dabcb25bb1ec9924d1f8388d551b63215381bd7f1180808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        signalProof.accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0f1c0f9507a3be8b6070650ae4ef4b2ca7c6325a3fac8694bd135680f94ca43cea0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";

        signalProof.storageProof[0] = hex"e3a120c503e3a6183486f40b26b20720d9fb44997221494d172cd9caf4192bc0b6980601";
    }

    /// @inheritdoc ISampleProof
    function getSignalDetails() public pure returns (address sender, bytes32 value) {
        sender = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        value = bytes32(0x404204dbc47bf04b49cf2fa2c69cf230c5bfcce81985444f7375c24620c37e88);
    }

    /// @inheritdoc ISampleProof
    function getSlot() public pure returns (bytes32 slot) {
        return 0x2e0dd2da160ce272c362f0db164918d90b0e72591a2e5cbe15c56eb8d15bda00;
    }
}
