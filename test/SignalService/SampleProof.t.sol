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
            stateRoot: bytes32(0x0c4473332e48e4afdd2d5f8abdbbbdc6fdc4b4acf9418e09cec5b13424a73c42),
            blockHash: bytes32(0x9808a73c0e2de3265e88e6d45eb51922ee6096cbdb763295226d83c5db0376d7)
        });

        signalProof.accountProof[0] =
            hex"f90131a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a097bff13eeebad2cda5e5d75582a6cdb37619ddc67c76d2b7eb06dea2bf8e62c5a006fbfb86513f6f9e20c355094efb981e17ae76c3472ad5e6c5f4a46d256cd0e98080a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0d566c7264cb6d498c47d8fa6127e05996afedf32737a7718081ac0c583e6b559a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        signalProof.accountProof[1] =
            hex"f85180808080a025b14e1ba874b7c7b7cda60e9000747c9529cc103d4400132182dd5854adbd0d80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        signalProof.accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0f1c0f9507a3be8b6070650ae4ef4b2ca7c6325a3fac8694bd135680f94ca43cea03e02a303e0a64f4588d05eaed8454840cdd10fe15cbfae680aa81923c5b8c9f0";

        signalProof.storageProof[0] = hex"e3a120c503e3a6183486f40b26b20720d9fb44997221494d172cd9caf4192bc0b6980601";
    }

    /// @inheritdoc ISampleProof
    function getSignalDetails() public pure returns (address sender, bytes32 value) {
        sender = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        value = bytes32(0x404204dbc47bf04b49cf2fa2c69cf230c5bfcce81985444f7375c24620c37e88);
    }

    /// @inheritdoc ISampleProof
    function getSlot() public pure returns (bytes32 slot) {
        return bytes32(0x2e0dd2da160ce272c362f0db164918d90b0e72591a2e5cbe15c56eb8d15bda00);
    }
}
