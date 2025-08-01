// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// This file is auto-generated with the command `just get-sample-deposit-proof`.
// Do not edit manually.
// See ISampleDepositProof.t.sol for an explanation of its purpose.

import {ISampleDepositProof} from "./ISampleDepositProof.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

contract SampleDepositProof is ISampleDepositProof {
    ISignalService.SignalProof[] private signalProofs;
    IETHBridge.ETHDeposit[] private deposits;
    bytes32[] private slots;
    bytes32[] private ids;

    constructor() {
        bytes[] memory accountProof;
        bytes[] memory storageProof;
        IETHBridge.ETHDeposit memory deposit;

        // Populate proof 0
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02dc7b0f3b9d71e01d1776f5ca0eb7a57f4a02f5f8cc058848c00ca726a7cd1cca06eea94cbcb3d10252c5c614c2c6fc4e7ca9d2ca9284101f2e15a7ac0783a365980a03839974d0c6a1eca8831503493d9062720b079ff90a2a94d3ba2a23f0cacda86a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a03844de65ae5d0e8e876f23dd945b43e96b2a277fb146da7cf9101fcb6d1f4fc8a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a09687ca44cd5b97a4ceac68020c94e024d205cf3fd77ef8685eedd0d939a8079380808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a00de5b19f0cfcc623c52adb2af3888e095d0b16e201bf4ee6813bc2ebc0098174a0b004c0ad2e8b589db7b80221a2d4be8a62ba3a982a196f419fce4848f1616f5e";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8b18080a01243c170fb1367c66d6aa47914d71e1d70a051487daa67f169dd329f8ce63636a0c669635fcfb9d57cc561468366bdea98166d38e1c4c3576ffa2892382be52c82a02184203f0c459f217d27413da5bad909b09a06bedc906b109cd59e343f2fa3ef808080808080a0c34604dd50b3750709360364fc4d95cc5720a0f03aae8bb5f39c51f9e0103a638080a0c96f3ecfcab0dd21cefe8a7d2e350df672603f73ec7e8454144ec3c3f560b2b88080";
        storageProof[1] =
            hex"f8718080808080808080808080a00d87c1d4a9856b195ee699d505add2b7a1fcc99b8424ba7331739cb01ae1505da05988b2333c9e7203ed020706525ef19348a2685f72ad057bf58fa479a9ae6a0980a07ae420fe90452ab2374f8ae4b9aa5eabdae0aa042829febe1ef09c111188cbb08080";
        storageProof[2] = hex"e2a02020858fa36572158255592dd4252184b8dcddfa7dd66d8bafac0c21be9247f801";
        deposit.nonce = 0;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x006217c47ffA5Eb3F3c92247ffFE22AD998242c5);
        deposit.amount = 0;
        deposit.data = bytes(hex"");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x58887ff218f2583e37373509606997e41dfbd96b6b5a236aaacc1e9ef0472900),
            bytes32(0x2d04141ab42f1e60d740a5a131f07aa6865af7efed674eef1aec49c3b20416a4)
        );

        // Populate proof 1
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02dc7b0f3b9d71e01d1776f5ca0eb7a57f4a02f5f8cc058848c00ca726a7cd1cca06eea94cbcb3d10252c5c614c2c6fc4e7ca9d2ca9284101f2e15a7ac0783a365980a03839974d0c6a1eca8831503493d9062720b079ff90a2a94d3ba2a23f0cacda86a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a03844de65ae5d0e8e876f23dd945b43e96b2a277fb146da7cf9101fcb6d1f4fc8a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a09687ca44cd5b97a4ceac68020c94e024d205cf3fd77ef8685eedd0d939a8079380808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a00de5b19f0cfcc623c52adb2af3888e095d0b16e201bf4ee6813bc2ebc0098174a0b004c0ad2e8b589db7b80221a2d4be8a62ba3a982a196f419fce4848f1616f5e";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8b18080a01243c170fb1367c66d6aa47914d71e1d70a051487daa67f169dd329f8ce63636a0c669635fcfb9d57cc561468366bdea98166d38e1c4c3576ffa2892382be52c82a02184203f0c459f217d27413da5bad909b09a06bedc906b109cd59e343f2fa3ef808080808080a0c34604dd50b3750709360364fc4d95cc5720a0f03aae8bb5f39c51f9e0103a638080a0c96f3ecfcab0dd21cefe8a7d2e350df672603f73ec7e8454144ec3c3f560b2b88080";
        storageProof[1] =
            hex"f8718080808080808080808080a00d87c1d4a9856b195ee699d505add2b7a1fcc99b8424ba7331739cb01ae1505da05988b2333c9e7203ed020706525ef19348a2685f72ad057bf58fa479a9ae6a0980a07ae420fe90452ab2374f8ae4b9aa5eabdae0aa042829febe1ef09c111188cbb08080";
        storageProof[2] = hex"e2a020064e5d751baf5ba810a000ab852d98ab2d42de5db067a7bd1284c849961a4201";
        deposit.nonce = 1;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x006217c47ffA5Eb3F3c92247ffFE22AD998242c5);
        deposit.amount = 0;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xdb5b63f47edc0299380a3fe693304cadc397fbd6545338f60909b1e11ac37f00),
            bytes32(0xc7e6a3680fbabbe54f252da30fb2ad9d8d55e02076c55581a154e6eec59853cb)
        );

        // Populate proof 2
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02dc7b0f3b9d71e01d1776f5ca0eb7a57f4a02f5f8cc058848c00ca726a7cd1cca06eea94cbcb3d10252c5c614c2c6fc4e7ca9d2ca9284101f2e15a7ac0783a365980a03839974d0c6a1eca8831503493d9062720b079ff90a2a94d3ba2a23f0cacda86a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a03844de65ae5d0e8e876f23dd945b43e96b2a277fb146da7cf9101fcb6d1f4fc8a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a09687ca44cd5b97a4ceac68020c94e024d205cf3fd77ef8685eedd0d939a8079380808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a00de5b19f0cfcc623c52adb2af3888e095d0b16e201bf4ee6813bc2ebc0098174a0b004c0ad2e8b589db7b80221a2d4be8a62ba3a982a196f419fce4848f1616f5e";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8b18080a01243c170fb1367c66d6aa47914d71e1d70a051487daa67f169dd329f8ce63636a0c669635fcfb9d57cc561468366bdea98166d38e1c4c3576ffa2892382be52c82a02184203f0c459f217d27413da5bad909b09a06bedc906b109cd59e343f2fa3ef808080808080a0c34604dd50b3750709360364fc4d95cc5720a0f03aae8bb5f39c51f9e0103a638080a0c96f3ecfcab0dd21cefe8a7d2e350df672603f73ec7e8454144ec3c3f560b2b88080";
        storageProof[1] = hex"e2a03355eab8e496e0c877a6644518b64d963b15d7e42d586e4ee997a52562ee9e6601";
        deposit.nonce = 2;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x006217c47ffA5Eb3F3c92247ffFE22AD998242c5);
        deposit.amount = 0;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d3");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xe2c10eb6f6079601ef8a47131d553d6402ebc6e5634b46927bd5d0a2bc9c0600),
            bytes32(0xfa50d1dc414c74ffa3ba764c8eb132fa50b0c78dd857883a7622dcc381095057)
        );

        // Populate proof 3
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02dc7b0f3b9d71e01d1776f5ca0eb7a57f4a02f5f8cc058848c00ca726a7cd1cca06eea94cbcb3d10252c5c614c2c6fc4e7ca9d2ca9284101f2e15a7ac0783a365980a03839974d0c6a1eca8831503493d9062720b079ff90a2a94d3ba2a23f0cacda86a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a03844de65ae5d0e8e876f23dd945b43e96b2a277fb146da7cf9101fcb6d1f4fc8a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a09687ca44cd5b97a4ceac68020c94e024d205cf3fd77ef8685eedd0d939a8079380808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a00de5b19f0cfcc623c52adb2af3888e095d0b16e201bf4ee6813bc2ebc0098174a0b004c0ad2e8b589db7b80221a2d4be8a62ba3a982a196f419fce4848f1616f5e";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8b18080a01243c170fb1367c66d6aa47914d71e1d70a051487daa67f169dd329f8ce63636a0c669635fcfb9d57cc561468366bdea98166d38e1c4c3576ffa2892382be52c82a02184203f0c459f217d27413da5bad909b09a06bedc906b109cd59e343f2fa3ef808080808080a0c34604dd50b3750709360364fc4d95cc5720a0f03aae8bb5f39c51f9e0103a638080a0c96f3ecfcab0dd21cefe8a7d2e350df672603f73ec7e8454144ec3c3f560b2b88080";
        storageProof[1] =
            hex"f8718080808080808080808080a00d87c1d4a9856b195ee699d505add2b7a1fcc99b8424ba7331739cb01ae1505da05988b2333c9e7203ed020706525ef19348a2685f72ad057bf58fa479a9ae6a0980a07ae420fe90452ab2374f8ae4b9aa5eabdae0aa042829febe1ef09c111188cbb08080";
        storageProof[2] = hex"e2a020a5e16886f9569fc1d10f1a5b6f5388270af61ee808596dce95b45ef96578fa01";
        deposit.nonce = 3;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x006217c47ffA5Eb3F3c92247ffFE22AD998242c5);
        deposit.amount = 0;
        deposit.data = bytes(hex"5932a71200000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x21baf89acef14f3316986298be8f92a205be61339bb2d1e2d9df06d49c33dd00),
            bytes32(0x67889b8f4911de8a705033cfbe00bbed9d87c75bd76eea7a23f53a32b0be4eb2)
        );

        // Populate proof 4
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02dc7b0f3b9d71e01d1776f5ca0eb7a57f4a02f5f8cc058848c00ca726a7cd1cca06eea94cbcb3d10252c5c614c2c6fc4e7ca9d2ca9284101f2e15a7ac0783a365980a03839974d0c6a1eca8831503493d9062720b079ff90a2a94d3ba2a23f0cacda86a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a03844de65ae5d0e8e876f23dd945b43e96b2a277fb146da7cf9101fcb6d1f4fc8a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a09687ca44cd5b97a4ceac68020c94e024d205cf3fd77ef8685eedd0d939a8079380808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a00de5b19f0cfcc623c52adb2af3888e095d0b16e201bf4ee6813bc2ebc0098174a0b004c0ad2e8b589db7b80221a2d4be8a62ba3a982a196f419fce4848f1616f5e";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8b18080a01243c170fb1367c66d6aa47914d71e1d70a051487daa67f169dd329f8ce63636a0c669635fcfb9d57cc561468366bdea98166d38e1c4c3576ffa2892382be52c82a02184203f0c459f217d27413da5bad909b09a06bedc906b109cd59e343f2fa3ef808080808080a0c34604dd50b3750709360364fc4d95cc5720a0f03aae8bb5f39c51f9e0103a638080a0c96f3ecfcab0dd21cefe8a7d2e350df672603f73ec7e8454144ec3c3f560b2b88080";
        storageProof[1] = hex"e2a03ca5bae38c2882532797a1e415bdc25b8b3d757c9f4a25d0045447c11f44c6a001";
        deposit.nonce = 4;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x006217c47ffA5Eb3F3c92247ffFE22AD998242c5);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x2cfbd4a9e77589dd1b8ba127277d3e3e268382bb9342282b81a44e650bd49f00),
            bytes32(0x8ed609e11bd6c25677d61324b2a88293233ad6a46e5cfa89a31adfc61ffb1515)
        );

        // Populate proof 5
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02dc7b0f3b9d71e01d1776f5ca0eb7a57f4a02f5f8cc058848c00ca726a7cd1cca06eea94cbcb3d10252c5c614c2c6fc4e7ca9d2ca9284101f2e15a7ac0783a365980a03839974d0c6a1eca8831503493d9062720b079ff90a2a94d3ba2a23f0cacda86a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a03844de65ae5d0e8e876f23dd945b43e96b2a277fb146da7cf9101fcb6d1f4fc8a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a09687ca44cd5b97a4ceac68020c94e024d205cf3fd77ef8685eedd0d939a8079380808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a00de5b19f0cfcc623c52adb2af3888e095d0b16e201bf4ee6813bc2ebc0098174a0b004c0ad2e8b589db7b80221a2d4be8a62ba3a982a196f419fce4848f1616f5e";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8b18080a01243c170fb1367c66d6aa47914d71e1d70a051487daa67f169dd329f8ce63636a0c669635fcfb9d57cc561468366bdea98166d38e1c4c3576ffa2892382be52c82a02184203f0c459f217d27413da5bad909b09a06bedc906b109cd59e343f2fa3ef808080808080a0c34604dd50b3750709360364fc4d95cc5720a0f03aae8bb5f39c51f9e0103a638080a0c96f3ecfcab0dd21cefe8a7d2e350df672603f73ec7e8454144ec3c3f560b2b88080";
        storageProof[1] =
            hex"f851a033eb6958e121505b7893755b6d99acc29d0a96567a3e4eb84ad4fe12bf7b75e6808080808080808080a0f331a5357c2c8b8ad5663215f1a7f329670a9bd995f6a3edec9b85638cfefb32808080808080";
        storageProof[2] = hex"e2a02036961ea12d2a0af357d42cc777f6bbce82bb8964045e468b8f634223e97a3101";
        deposit.nonce = 5;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x006217c47ffA5Eb3F3c92247ffFE22AD998242c5);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x8d6e366da1d1a183150d88d00c65dd9632870fa4bd29242749a828e84724a000),
            bytes32(0x4d28311f702259a707c4c710de11a1df32db8cd733733e8e85e15f0d62c38857)
        );

        // Populate proof 6
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02dc7b0f3b9d71e01d1776f5ca0eb7a57f4a02f5f8cc058848c00ca726a7cd1cca06eea94cbcb3d10252c5c614c2c6fc4e7ca9d2ca9284101f2e15a7ac0783a365980a03839974d0c6a1eca8831503493d9062720b079ff90a2a94d3ba2a23f0cacda86a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a03844de65ae5d0e8e876f23dd945b43e96b2a277fb146da7cf9101fcb6d1f4fc8a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a09687ca44cd5b97a4ceac68020c94e024d205cf3fd77ef8685eedd0d939a8079380808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a00de5b19f0cfcc623c52adb2af3888e095d0b16e201bf4ee6813bc2ebc0098174a0b004c0ad2e8b589db7b80221a2d4be8a62ba3a982a196f419fce4848f1616f5e";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8b18080a01243c170fb1367c66d6aa47914d71e1d70a051487daa67f169dd329f8ce63636a0c669635fcfb9d57cc561468366bdea98166d38e1c4c3576ffa2892382be52c82a02184203f0c459f217d27413da5bad909b09a06bedc906b109cd59e343f2fa3ef808080808080a0c34604dd50b3750709360364fc4d95cc5720a0f03aae8bb5f39c51f9e0103a638080a0c96f3ecfcab0dd21cefe8a7d2e350df672603f73ec7e8454144ec3c3f560b2b88080";
        storageProof[1] =
            hex"f851a033eb6958e121505b7893755b6d99acc29d0a96567a3e4eb84ad4fe12bf7b75e6808080808080808080a0f331a5357c2c8b8ad5663215f1a7f329670a9bd995f6a3edec9b85638cfefb32808080808080";
        storageProof[2] = hex"e2a020d753c6d0021760ebafd645ed76e06a4143a03a9047a5db312d02cd35b00f8601";
        deposit.nonce = 6;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x006217c47ffA5Eb3F3c92247ffFE22AD998242c5);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d3");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x7f83d89c4f105f441e0009fb4335eec5aab55353bfd0e4a046813f81fc8fe600),
            bytes32(0x40ed46291c61c227a0aa118fa80c2d6ff5d745f7bfa85e9f8927cf1e8878f150)
        );

        // Populate proof 7
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02dc7b0f3b9d71e01d1776f5ca0eb7a57f4a02f5f8cc058848c00ca726a7cd1cca06eea94cbcb3d10252c5c614c2c6fc4e7ca9d2ca9284101f2e15a7ac0783a365980a03839974d0c6a1eca8831503493d9062720b079ff90a2a94d3ba2a23f0cacda86a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a03844de65ae5d0e8e876f23dd945b43e96b2a277fb146da7cf9101fcb6d1f4fc8a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a09687ca44cd5b97a4ceac68020c94e024d205cf3fd77ef8685eedd0d939a8079380808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a00de5b19f0cfcc623c52adb2af3888e095d0b16e201bf4ee6813bc2ebc0098174a0b004c0ad2e8b589db7b80221a2d4be8a62ba3a982a196f419fce4848f1616f5e";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8b18080a01243c170fb1367c66d6aa47914d71e1d70a051487daa67f169dd329f8ce63636a0c669635fcfb9d57cc561468366bdea98166d38e1c4c3576ffa2892382be52c82a02184203f0c459f217d27413da5bad909b09a06bedc906b109cd59e343f2fa3ef808080808080a0c34604dd50b3750709360364fc4d95cc5720a0f03aae8bb5f39c51f9e0103a638080a0c96f3ecfcab0dd21cefe8a7d2e350df672603f73ec7e8454144ec3c3f560b2b88080";
        storageProof[1] = hex"e2a03e5c83eba42cae419ace36c50da8ec0a0ba27fc69a6d03d07e00bef6d69ea2ee01";
        deposit.nonce = 7;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x006217c47ffA5Eb3F3c92247ffFE22AD998242c5);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"5932a71200000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x46638e69576cb0ad6fe3711d605ac512e423414c192df77ab8b542e3a95f2b00),
            bytes32(0xb59a1cfc7f461a83c3a4f326bba8b4546c19a25589be53ee32dbc6aba8f3c639)
        );
    }

    /// @inheritdoc ISampleDepositProof
    function getSignalServiceAddress() public pure returns (address) {
        return address(0x5FbDB2315678afecb367f032d93F642f64180aa3);
    }

    /// @inheritdoc ISampleDepositProof
    function getBridgeAddress() public pure returns (address) {
        return address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
    }

    /// @inheritdoc ISampleDepositProof
    function getStateRoot() public pure returns (bytes32) {
        return bytes32(0xac16ef4302130a675256acb0606429e7d1963f7ec5cb0ca8c4b2562e075f9b94);
    }

    /// @inheritdoc ISampleDepositProof
    function getBlockHash() public pure returns (bytes32) {
        return bytes32(0xbc9016409878723d2d9f7dee69f0a27c76405010c7536ef8cc2eb9e81cf56eca);
    }

    /// @inheritdoc ISampleDepositProof
    function getDepositSignalProof(uint256 idx) public view returns (ISignalService.SignalProof memory signalProof) {
        return signalProofs[idx];
    }

    /// @inheritdoc ISampleDepositProof
    function getEthDeposit(uint256 idx) public view returns (IETHBridge.ETHDeposit memory deposit) {
        return deposits[idx];
    }

    /// @inheritdoc ISampleDepositProof
    function getDepositInternals(uint256 idx) public view returns (bytes32 slot, bytes32 id) {
        return (slots[idx], ids[idx]);
    }

    function _createDeposit(
        bytes[] memory accountProof,
        bytes[] memory storageProof,
        IETHBridge.ETHDeposit memory deposit,
        bytes32 slot,
        bytes32 id
    ) internal {
        signalProofs.push(
            ISignalService.SignalProof({
                accountProof: accountProof,
                storageProof: storageProof,
                stateRoot: getStateRoot(),
                blockHash: getBlockHash()
            })
        );
        deposits.push(deposit);
        slots.push(slot);
        ids.push(id);
    }

    function getNumberOfProofs() public view returns (uint256 count) {
        count = signalProofs.length;
        require(deposits.length == count, "Deposits length mismatch");
        require(slots.length == count, "Slots length mismatch");
        require(ids.length == count, "Ids length mismatch");
    }
}
