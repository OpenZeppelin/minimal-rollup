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
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02ea1e92e6cb7173117f480e3fd33185068e655508d6d9b7986a6991e64b6c865a0080fde2865383740d520ac651f6037ff1d0721423639e54f00476a409f443caf80a05f22be3c325366e6ed899d039e7dd20ea7b466798fa8fd5963852ecebf4e56b3a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a098ddc0cda51e9af687f6cda58e0f4a5d9acd99bfa60922f07c03374062b553cca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0d2d52324483a577d97c6066f9e130d00c58275412808e1c99b30fda3595f014b80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a045aaa662830dc5c67aee9dc886c1f5638be154a58de94a2087bf3cf209178a7da0941e869b0337ac6d16ec0814dabf95e76886605d005f3280c4dc276b1ee6e016";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f901118080a08c5f183847a3164d2af1fccae211c43b32745b5ba0bd4efb6d4a641fcf8eff2ba096ce2d8ed1b8aedb02b7248703c4899364ee3bf70c93dc99aa75a0d86db4bf03a0b9fa3e84338318a35f23147764f475d2c1803b93d239c70f23d09b532470d06ea0710e558b2c1d3862e884a2abffa1c82f2ca3297ee6b3b2af127d3fc42d8a6d19a00ab13306396605ed18d72b341bbe585e5948cbebddea813ff4040afcb08e3ceaa01d582830fb0a387397723a1b00fcd7b20078802af81224776ca606609f18f8ed8080a0f6ab58118af2be0ae25fafc1d9e0a4c2218357c88f91768872ec43b5745795dd8080a066e5e85536e13952d7ae3d0e2274aca5003f5fffd0c5404f7ea544456278a193808080";
        storageProof[1] = hex"e2a0358693f503641099a1861efc44174580451adb33da479267f67dc12a8668453001";
        deposit.nonce = 0;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0xf9f5C5411F0bEf1880cE3B051BD14196479764D2);
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xfe97aa9c92e33e9443104a0c0b7371724b3a0020e7b9fe6e384c5fb95f32ed00),
            bytes32(0xf2dc10a33f63dae4a3b8b76f9a9f19f640cecd9c6c62a62a1d0e6374caa2926d)
        );

        // Populate proof 1
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02ea1e92e6cb7173117f480e3fd33185068e655508d6d9b7986a6991e64b6c865a0080fde2865383740d520ac651f6037ff1d0721423639e54f00476a409f443caf80a05f22be3c325366e6ed899d039e7dd20ea7b466798fa8fd5963852ecebf4e56b3a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a098ddc0cda51e9af687f6cda58e0f4a5d9acd99bfa60922f07c03374062b553cca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0d2d52324483a577d97c6066f9e130d00c58275412808e1c99b30fda3595f014b80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a045aaa662830dc5c67aee9dc886c1f5638be154a58de94a2087bf3cf209178a7da0941e869b0337ac6d16ec0814dabf95e76886605d005f3280c4dc276b1ee6e016";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f901118080a08c5f183847a3164d2af1fccae211c43b32745b5ba0bd4efb6d4a641fcf8eff2ba096ce2d8ed1b8aedb02b7248703c4899364ee3bf70c93dc99aa75a0d86db4bf03a0b9fa3e84338318a35f23147764f475d2c1803b93d239c70f23d09b532470d06ea0710e558b2c1d3862e884a2abffa1c82f2ca3297ee6b3b2af127d3fc42d8a6d19a00ab13306396605ed18d72b341bbe585e5948cbebddea813ff4040afcb08e3ceaa01d582830fb0a387397723a1b00fcd7b20078802af81224776ca606609f18f8ed8080a0f6ab58118af2be0ae25fafc1d9e0a4c2218357c88f91768872ec43b5745795dd8080a066e5e85536e13952d7ae3d0e2274aca5003f5fffd0c5404f7ea544456278a193808080";
        storageProof[1] = hex"e2a036cefd9ac7aa8aad44275648ca7193500e3b670e774f4ffeacce9744ecb3d73401";
        deposit.nonce = 1;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0xf9f5C5411F0bEf1880cE3B051BD14196479764D2);
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xe3e0bfbf835c03bedf947f24109d3f6c0f0d6b48d07209a2ac97d67b34990300),
            bytes32(0x530c559481cc116d9025e0bf153363e18767ad75e3f8a202107ce33345620ae0)
        );

        // Populate proof 2
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02ea1e92e6cb7173117f480e3fd33185068e655508d6d9b7986a6991e64b6c865a0080fde2865383740d520ac651f6037ff1d0721423639e54f00476a409f443caf80a05f22be3c325366e6ed899d039e7dd20ea7b466798fa8fd5963852ecebf4e56b3a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a098ddc0cda51e9af687f6cda58e0f4a5d9acd99bfa60922f07c03374062b553cca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0d2d52324483a577d97c6066f9e130d00c58275412808e1c99b30fda3595f014b80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a045aaa662830dc5c67aee9dc886c1f5638be154a58de94a2087bf3cf209178a7da0941e869b0337ac6d16ec0814dabf95e76886605d005f3280c4dc276b1ee6e016";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f901118080a08c5f183847a3164d2af1fccae211c43b32745b5ba0bd4efb6d4a641fcf8eff2ba096ce2d8ed1b8aedb02b7248703c4899364ee3bf70c93dc99aa75a0d86db4bf03a0b9fa3e84338318a35f23147764f475d2c1803b93d239c70f23d09b532470d06ea0710e558b2c1d3862e884a2abffa1c82f2ca3297ee6b3b2af127d3fc42d8a6d19a00ab13306396605ed18d72b341bbe585e5948cbebddea813ff4040afcb08e3ceaa01d582830fb0a387397723a1b00fcd7b20078802af81224776ca606609f18f8ed8080a0f6ab58118af2be0ae25fafc1d9e0a4c2218357c88f91768872ec43b5745795dd8080a066e5e85536e13952d7ae3d0e2274aca5003f5fffd0c5404f7ea544456278a193808080";
        storageProof[1] = hex"e2a0377c2ce50abd193c6c9014228a73ea97269ecb51a0f0195b9f44c080e2ff5ad201";
        deposit.nonce = 2;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d3");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0xf9f5C5411F0bEf1880cE3B051BD14196479764D2);
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xf0d507bf2a13757b7cf6963614a4b071304da098683247be5f07ed6cd69bce00),
            bytes32(0x1442e0d7ad2ae4c7dff87ab98fc7a83b5b16d5f5d36f69c5395651f4054f47ca)
        );

        // Populate proof 3
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02ea1e92e6cb7173117f480e3fd33185068e655508d6d9b7986a6991e64b6c865a0080fde2865383740d520ac651f6037ff1d0721423639e54f00476a409f443caf80a05f22be3c325366e6ed899d039e7dd20ea7b466798fa8fd5963852ecebf4e56b3a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a098ddc0cda51e9af687f6cda58e0f4a5d9acd99bfa60922f07c03374062b553cca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0d2d52324483a577d97c6066f9e130d00c58275412808e1c99b30fda3595f014b80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a045aaa662830dc5c67aee9dc886c1f5638be154a58de94a2087bf3cf209178a7da0941e869b0337ac6d16ec0814dabf95e76886605d005f3280c4dc276b1ee6e016";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f901118080a08c5f183847a3164d2af1fccae211c43b32745b5ba0bd4efb6d4a641fcf8eff2ba096ce2d8ed1b8aedb02b7248703c4899364ee3bf70c93dc99aa75a0d86db4bf03a0b9fa3e84338318a35f23147764f475d2c1803b93d239c70f23d09b532470d06ea0710e558b2c1d3862e884a2abffa1c82f2ca3297ee6b3b2af127d3fc42d8a6d19a00ab13306396605ed18d72b341bbe585e5948cbebddea813ff4040afcb08e3ceaa01d582830fb0a387397723a1b00fcd7b20078802af81224776ca606609f18f8ed8080a0f6ab58118af2be0ae25fafc1d9e0a4c2218357c88f91768872ec43b5745795dd8080a066e5e85536e13952d7ae3d0e2274aca5003f5fffd0c5404f7ea544456278a193808080";
        storageProof[1] = hex"e2a03fe6aca95ee567db22b9d8dcd52067878472fc5f090f2f2cee0be53dd68c2c0901";
        deposit.nonce = 3;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"5932a71200000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0xf9f5C5411F0bEf1880cE3B051BD14196479764D2);
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x9c6a0354ea48f6f6b6aa630e0b620698f69d6a8ad4ecca758d9d34aba195b400),
            bytes32(0xfe9a082e9465578ff70da97a6edfe8b4afad0f3bfaeff6ac0c08effd118c54f7)
        );

        // Populate proof 4
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02ea1e92e6cb7173117f480e3fd33185068e655508d6d9b7986a6991e64b6c865a0080fde2865383740d520ac651f6037ff1d0721423639e54f00476a409f443caf80a05f22be3c325366e6ed899d039e7dd20ea7b466798fa8fd5963852ecebf4e56b3a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a098ddc0cda51e9af687f6cda58e0f4a5d9acd99bfa60922f07c03374062b553cca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0d2d52324483a577d97c6066f9e130d00c58275412808e1c99b30fda3595f014b80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a045aaa662830dc5c67aee9dc886c1f5638be154a58de94a2087bf3cf209178a7da0941e869b0337ac6d16ec0814dabf95e76886605d005f3280c4dc276b1ee6e016";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f901118080a08c5f183847a3164d2af1fccae211c43b32745b5ba0bd4efb6d4a641fcf8eff2ba096ce2d8ed1b8aedb02b7248703c4899364ee3bf70c93dc99aa75a0d86db4bf03a0b9fa3e84338318a35f23147764f475d2c1803b93d239c70f23d09b532470d06ea0710e558b2c1d3862e884a2abffa1c82f2ca3297ee6b3b2af127d3fc42d8a6d19a00ab13306396605ed18d72b341bbe585e5948cbebddea813ff4040afcb08e3ceaa01d582830fb0a387397723a1b00fcd7b20078802af81224776ca606609f18f8ed8080a0f6ab58118af2be0ae25fafc1d9e0a4c2218357c88f91768872ec43b5745795dd8080a066e5e85536e13952d7ae3d0e2274aca5003f5fffd0c5404f7ea544456278a193808080";
        storageProof[1] = hex"e2a030bc72e321ee1d414699e06be4e5518728ac158dab01a21b01ee12d2bd2cd31901";
        deposit.nonce = 4;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0xf9f5C5411F0bEf1880cE3B051BD14196479764D2);
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xf014786f0c5fe4dd2b28ee1a9aa5af98362f2c193194f81430ac76b1f58d2800),
            bytes32(0x361c927d7ea5f36f846bd0e0c2b0eb2e1e70aeca48a0f0e530bf1e1032f59fe4)
        );

        // Populate proof 5
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02ea1e92e6cb7173117f480e3fd33185068e655508d6d9b7986a6991e64b6c865a0080fde2865383740d520ac651f6037ff1d0721423639e54f00476a409f443caf80a05f22be3c325366e6ed899d039e7dd20ea7b466798fa8fd5963852ecebf4e56b3a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a098ddc0cda51e9af687f6cda58e0f4a5d9acd99bfa60922f07c03374062b553cca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0d2d52324483a577d97c6066f9e130d00c58275412808e1c99b30fda3595f014b80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a045aaa662830dc5c67aee9dc886c1f5638be154a58de94a2087bf3cf209178a7da0941e869b0337ac6d16ec0814dabf95e76886605d005f3280c4dc276b1ee6e016";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f901118080a08c5f183847a3164d2af1fccae211c43b32745b5ba0bd4efb6d4a641fcf8eff2ba096ce2d8ed1b8aedb02b7248703c4899364ee3bf70c93dc99aa75a0d86db4bf03a0b9fa3e84338318a35f23147764f475d2c1803b93d239c70f23d09b532470d06ea0710e558b2c1d3862e884a2abffa1c82f2ca3297ee6b3b2af127d3fc42d8a6d19a00ab13306396605ed18d72b341bbe585e5948cbebddea813ff4040afcb08e3ceaa01d582830fb0a387397723a1b00fcd7b20078802af81224776ca606609f18f8ed8080a0f6ab58118af2be0ae25fafc1d9e0a4c2218357c88f91768872ec43b5745795dd8080a066e5e85536e13952d7ae3d0e2274aca5003f5fffd0c5404f7ea544456278a193808080";
        storageProof[1] = hex"e2a03ac3de17f671e61277a1eb16d9b36f9054af4b54a1255b76aa5e97635d7097e101";
        deposit.nonce = 5;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0xf9f5C5411F0bEf1880cE3B051BD14196479764D2);
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xc49d9d332db808565bdc8eeb44be4979fc5584bbf3aeaba7db7ea53713200600),
            bytes32(0x0851809cbcca6c18f60fbed131128bcd0033977bd9e849146142a09f279f203f)
        );

        // Populate proof 6
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02ea1e92e6cb7173117f480e3fd33185068e655508d6d9b7986a6991e64b6c865a0080fde2865383740d520ac651f6037ff1d0721423639e54f00476a409f443caf80a05f22be3c325366e6ed899d039e7dd20ea7b466798fa8fd5963852ecebf4e56b3a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a098ddc0cda51e9af687f6cda58e0f4a5d9acd99bfa60922f07c03374062b553cca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0d2d52324483a577d97c6066f9e130d00c58275412808e1c99b30fda3595f014b80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a045aaa662830dc5c67aee9dc886c1f5638be154a58de94a2087bf3cf209178a7da0941e869b0337ac6d16ec0814dabf95e76886605d005f3280c4dc276b1ee6e016";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f901118080a08c5f183847a3164d2af1fccae211c43b32745b5ba0bd4efb6d4a641fcf8eff2ba096ce2d8ed1b8aedb02b7248703c4899364ee3bf70c93dc99aa75a0d86db4bf03a0b9fa3e84338318a35f23147764f475d2c1803b93d239c70f23d09b532470d06ea0710e558b2c1d3862e884a2abffa1c82f2ca3297ee6b3b2af127d3fc42d8a6d19a00ab13306396605ed18d72b341bbe585e5948cbebddea813ff4040afcb08e3ceaa01d582830fb0a387397723a1b00fcd7b20078802af81224776ca606609f18f8ed8080a0f6ab58118af2be0ae25fafc1d9e0a4c2218357c88f91768872ec43b5745795dd8080a066e5e85536e13952d7ae3d0e2274aca5003f5fffd0c5404f7ea544456278a193808080";
        storageProof[1] = hex"e2a0367baf079ef5a1697eff8bd262374e7734950f77b0ea0cc3d88369c0737a226701";
        deposit.nonce = 6;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d3");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0xf9f5C5411F0bEf1880cE3B051BD14196479764D2);
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xb4f856ea53863d60d822452285d7c8c68258115f0d2e0f84ceb190a462925800),
            bytes32(0x44afb31d90afcd53cc180ea63aceb942ca935260cb4c9938cff466b6280b09ef)
        );

        // Populate proof 7
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a02ea1e92e6cb7173117f480e3fd33185068e655508d6d9b7986a6991e64b6c865a0080fde2865383740d520ac651f6037ff1d0721423639e54f00476a409f443caf80a05f22be3c325366e6ed899d039e7dd20ea7b466798fa8fd5963852ecebf4e56b3a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a098ddc0cda51e9af687f6cda58e0f4a5d9acd99bfa60922f07c03374062b553cca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0d2d52324483a577d97c6066f9e130d00c58275412808e1c99b30fda3595f014b80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a045aaa662830dc5c67aee9dc886c1f5638be154a58de94a2087bf3cf209178a7da0941e869b0337ac6d16ec0814dabf95e76886605d005f3280c4dc276b1ee6e016";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f901118080a08c5f183847a3164d2af1fccae211c43b32745b5ba0bd4efb6d4a641fcf8eff2ba096ce2d8ed1b8aedb02b7248703c4899364ee3bf70c93dc99aa75a0d86db4bf03a0b9fa3e84338318a35f23147764f475d2c1803b93d239c70f23d09b532470d06ea0710e558b2c1d3862e884a2abffa1c82f2ca3297ee6b3b2af127d3fc42d8a6d19a00ab13306396605ed18d72b341bbe585e5948cbebddea813ff4040afcb08e3ceaa01d582830fb0a387397723a1b00fcd7b20078802af81224776ca606609f18f8ed8080a0f6ab58118af2be0ae25fafc1d9e0a4c2218357c88f91768872ec43b5745795dd8080a066e5e85536e13952d7ae3d0e2274aca5003f5fffd0c5404f7ea544456278a193808080";
        storageProof[1] = hex"e2a0369d050420bb0f797e6088c7810b502ec36bdc811bb2722ad2ceca8f53f5b3a401";
        deposit.nonce = 7;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"5932a71200000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0xf9f5C5411F0bEf1880cE3B051BD14196479764D2);
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x2f340dd08c7b9eafd5cdd5097224c3d575a06e6d45dd5fb4227ffed1ecbad000),
            bytes32(0x55a2cffcb5504a5fd544ca3f7bf97923f6c57174be5013898d534d9c68072329)
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
        return bytes32(0xaf2b8c521afbda1af6d5564b8f6a31a83aa03e8f5fc460e1a2a22e0ed63762e7);
    }

    /// @inheritdoc ISampleDepositProof
    function getBlockHash() public pure returns (bytes32) {
        return bytes32(0x0e86695233fded5e6b8a1158c6b6bed9fa9c2e831112f6ed384b10615305ce0a);
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
