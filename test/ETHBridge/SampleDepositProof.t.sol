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
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0d4c4c8a14121232fc4007f741b713fb645400d2eb5a203a3ceffda94b0d34de8a04b3c813fea2ea4fb49cb0624da0fa4af42bb3d13d948495e0520cf7b561874f580a08b92251b0bf565aaeb9236c6ae2fc33e230327828456c5879b5feead26019d0fa04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a01b2645b5ef6d7c2ea61cde01854229586446f1efd88bcd2ed341bda170f721a7a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0c0b8f5ac2b3b9f4aec9f6f561c34ae79c8a09bfbb83c9b06aaaa0e38cd1bccfa80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a08a106988b9d42cf9b8f0b78ac295bb02aaf554744beee89c4cdf40fb77d22a98a07cd33d32a4359662287093f77885de8532b2b006d484908a2c146e2c22f9f66c";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8f1808080a00aa4241791bd906889dd0da533285296b645f0279de87b362c9530262bc5fad780a09f9c3b72b0b91adcf25afe4cdccf5dc6f85505ebed470f2e7ccbcd0c4267ca468080a00ca7f244fb353f3b34d938fab7bc94bb1ca4df7a9d268a28d40a04187aa4348aa0d54f9c40c3a6e8f61bc6a272d034833ab7323a33c786a95e7c097eaa9cee6db3a0023c2a92d7eb4a99982bcb52843e982da5d791e9e8c7a5ea2bf479d5a417a3e68080a0d7629ae444fa8e59a1e873003f1382831b26cfbf498b8935a4cfa751a3dba9cfa035f203538b0b9a2ad9dfe33acd23ae5a6a149a2591b12a5f22b807b6d7d05a8a8080";
        storageProof[1] = hex"e2a0300149a3893e04f1d87c0afeefb51e310d0c6edfa99eaff9b6bb484e452a375601";
        deposit.nonce = 0;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xcddcfd116b59f2bf811a2b4f7777b07ef300cc2c95b42a8dbe9b5445febbe500),
            bytes32(0xba167484c05d87b76d25426abaafe1c7ff160664255430be50fe39f57538d96e)
        );

        // Populate proof 1
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0d4c4c8a14121232fc4007f741b713fb645400d2eb5a203a3ceffda94b0d34de8a04b3c813fea2ea4fb49cb0624da0fa4af42bb3d13d948495e0520cf7b561874f580a08b92251b0bf565aaeb9236c6ae2fc33e230327828456c5879b5feead26019d0fa04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a01b2645b5ef6d7c2ea61cde01854229586446f1efd88bcd2ed341bda170f721a7a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0c0b8f5ac2b3b9f4aec9f6f561c34ae79c8a09bfbb83c9b06aaaa0e38cd1bccfa80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a08a106988b9d42cf9b8f0b78ac295bb02aaf554744beee89c4cdf40fb77d22a98a07cd33d32a4359662287093f77885de8532b2b006d484908a2c146e2c22f9f66c";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8f1808080a00aa4241791bd906889dd0da533285296b645f0279de87b362c9530262bc5fad780a09f9c3b72b0b91adcf25afe4cdccf5dc6f85505ebed470f2e7ccbcd0c4267ca468080a00ca7f244fb353f3b34d938fab7bc94bb1ca4df7a9d268a28d40a04187aa4348aa0d54f9c40c3a6e8f61bc6a272d034833ab7323a33c786a95e7c097eaa9cee6db3a0023c2a92d7eb4a99982bcb52843e982da5d791e9e8c7a5ea2bf479d5a417a3e68080a0d7629ae444fa8e59a1e873003f1382831b26cfbf498b8935a4cfa751a3dba9cfa035f203538b0b9a2ad9dfe33acd23ae5a6a149a2591b12a5f22b807b6d7d05a8a8080";
        storageProof[1] =
            hex"f85180808080808080a010c569c3182b0233310356d499333bec564e9bdbc3956603ff2d386b903380e0808080808080a051d40da49f0b2058f375e53d37b65cc1bdfd2def6a4f34a377a84f995a478f258080";
        storageProof[2] = hex"e2a020c7cf728ce6be0069bf86072a1feae06e0ea3ef98baa98bcc98cb0b2966844501";
        deposit.nonce = 1;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x48e3042f8a5a3b4214ccec0c1c81551f273b8a3c2471330137dd0bd4e9eeec00),
            bytes32(0xf0b3514850ce8c95bd0a66d0193c5ec6b89b2072cfde7df0b1c4ffdb81b2d17e)
        );

        // Populate proof 2
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0d4c4c8a14121232fc4007f741b713fb645400d2eb5a203a3ceffda94b0d34de8a04b3c813fea2ea4fb49cb0624da0fa4af42bb3d13d948495e0520cf7b561874f580a08b92251b0bf565aaeb9236c6ae2fc33e230327828456c5879b5feead26019d0fa04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a01b2645b5ef6d7c2ea61cde01854229586446f1efd88bcd2ed341bda170f721a7a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0c0b8f5ac2b3b9f4aec9f6f561c34ae79c8a09bfbb83c9b06aaaa0e38cd1bccfa80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a08a106988b9d42cf9b8f0b78ac295bb02aaf554744beee89c4cdf40fb77d22a98a07cd33d32a4359662287093f77885de8532b2b006d484908a2c146e2c22f9f66c";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8f1808080a00aa4241791bd906889dd0da533285296b645f0279de87b362c9530262bc5fad780a09f9c3b72b0b91adcf25afe4cdccf5dc6f85505ebed470f2e7ccbcd0c4267ca468080a00ca7f244fb353f3b34d938fab7bc94bb1ca4df7a9d268a28d40a04187aa4348aa0d54f9c40c3a6e8f61bc6a272d034833ab7323a33c786a95e7c097eaa9cee6db3a0023c2a92d7eb4a99982bcb52843e982da5d791e9e8c7a5ea2bf479d5a417a3e68080a0d7629ae444fa8e59a1e873003f1382831b26cfbf498b8935a4cfa751a3dba9cfa035f203538b0b9a2ad9dfe33acd23ae5a6a149a2591b12a5f22b807b6d7d05a8a8080";
        storageProof[1] = hex"e2a0385bbe9cf6df1de58ca59ceaa8e5e72d9f17ac631c4ceb733a243d28c61b0e7f01";
        deposit.nonce = 2;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d3");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xe7accf94cfb0573da2c8040e78fce9310e3e19d241b1419a0601340944138a00),
            bytes32(0x514a012708829ffa3acf9f45eac58babda307712b96750a4cd97f1110607e9b7)
        );

        // Populate proof 3
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0d4c4c8a14121232fc4007f741b713fb645400d2eb5a203a3ceffda94b0d34de8a04b3c813fea2ea4fb49cb0624da0fa4af42bb3d13d948495e0520cf7b561874f580a08b92251b0bf565aaeb9236c6ae2fc33e230327828456c5879b5feead26019d0fa04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a01b2645b5ef6d7c2ea61cde01854229586446f1efd88bcd2ed341bda170f721a7a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0c0b8f5ac2b3b9f4aec9f6f561c34ae79c8a09bfbb83c9b06aaaa0e38cd1bccfa80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a08a106988b9d42cf9b8f0b78ac295bb02aaf554744beee89c4cdf40fb77d22a98a07cd33d32a4359662287093f77885de8532b2b006d484908a2c146e2c22f9f66c";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8f1808080a00aa4241791bd906889dd0da533285296b645f0279de87b362c9530262bc5fad780a09f9c3b72b0b91adcf25afe4cdccf5dc6f85505ebed470f2e7ccbcd0c4267ca468080a00ca7f244fb353f3b34d938fab7bc94bb1ca4df7a9d268a28d40a04187aa4348aa0d54f9c40c3a6e8f61bc6a272d034833ab7323a33c786a95e7c097eaa9cee6db3a0023c2a92d7eb4a99982bcb52843e982da5d791e9e8c7a5ea2bf479d5a417a3e68080a0d7629ae444fa8e59a1e873003f1382831b26cfbf498b8935a4cfa751a3dba9cfa035f203538b0b9a2ad9dfe33acd23ae5a6a149a2591b12a5f22b807b6d7d05a8a8080";
        storageProof[1] = hex"e2a03410bfc273a0de73ef10c870520ab073cf2ac6a309a858fe175d82bee5b947a601";
        deposit.nonce = 3;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"5932a71200000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x4450c68b97c4b97ca27529350b817dc8e62e132803400eee1f43eb6b0afb6300),
            bytes32(0xe10b2203de1080c43ae4a7a5294cb2b55e3b81b6050be860754cce7e0014666f)
        );

        // Populate proof 4
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0d4c4c8a14121232fc4007f741b713fb645400d2eb5a203a3ceffda94b0d34de8a04b3c813fea2ea4fb49cb0624da0fa4af42bb3d13d948495e0520cf7b561874f580a08b92251b0bf565aaeb9236c6ae2fc33e230327828456c5879b5feead26019d0fa04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a01b2645b5ef6d7c2ea61cde01854229586446f1efd88bcd2ed341bda170f721a7a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0c0b8f5ac2b3b9f4aec9f6f561c34ae79c8a09bfbb83c9b06aaaa0e38cd1bccfa80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a08a106988b9d42cf9b8f0b78ac295bb02aaf554744beee89c4cdf40fb77d22a98a07cd33d32a4359662287093f77885de8532b2b006d484908a2c146e2c22f9f66c";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8f1808080a00aa4241791bd906889dd0da533285296b645f0279de87b362c9530262bc5fad780a09f9c3b72b0b91adcf25afe4cdccf5dc6f85505ebed470f2e7ccbcd0c4267ca468080a00ca7f244fb353f3b34d938fab7bc94bb1ca4df7a9d268a28d40a04187aa4348aa0d54f9c40c3a6e8f61bc6a272d034833ab7323a33c786a95e7c097eaa9cee6db3a0023c2a92d7eb4a99982bcb52843e982da5d791e9e8c7a5ea2bf479d5a417a3e68080a0d7629ae444fa8e59a1e873003f1382831b26cfbf498b8935a4cfa751a3dba9cfa035f203538b0b9a2ad9dfe33acd23ae5a6a149a2591b12a5f22b807b6d7d05a8a8080";
        storageProof[1] = hex"e2a030c827caae4f65d55cbcc5cf18b1a288fff930220ba05c64dac49c1793d93efe01";
        deposit.nonce = 4;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xd865eb2eabea8e4cb33eee05da7a855033859fc0116185bd0c999f22e931f400),
            bytes32(0xc2c8b34f099e5a2e833710c6ea1175480cde80a5058137d7283f4b940a3009ed)
        );

        // Populate proof 5
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0d4c4c8a14121232fc4007f741b713fb645400d2eb5a203a3ceffda94b0d34de8a04b3c813fea2ea4fb49cb0624da0fa4af42bb3d13d948495e0520cf7b561874f580a08b92251b0bf565aaeb9236c6ae2fc33e230327828456c5879b5feead26019d0fa04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a01b2645b5ef6d7c2ea61cde01854229586446f1efd88bcd2ed341bda170f721a7a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0c0b8f5ac2b3b9f4aec9f6f561c34ae79c8a09bfbb83c9b06aaaa0e38cd1bccfa80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a08a106988b9d42cf9b8f0b78ac295bb02aaf554744beee89c4cdf40fb77d22a98a07cd33d32a4359662287093f77885de8532b2b006d484908a2c146e2c22f9f66c";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8f1808080a00aa4241791bd906889dd0da533285296b645f0279de87b362c9530262bc5fad780a09f9c3b72b0b91adcf25afe4cdccf5dc6f85505ebed470f2e7ccbcd0c4267ca468080a00ca7f244fb353f3b34d938fab7bc94bb1ca4df7a9d268a28d40a04187aa4348aa0d54f9c40c3a6e8f61bc6a272d034833ab7323a33c786a95e7c097eaa9cee6db3a0023c2a92d7eb4a99982bcb52843e982da5d791e9e8c7a5ea2bf479d5a417a3e68080a0d7629ae444fa8e59a1e873003f1382831b26cfbf498b8935a4cfa751a3dba9cfa035f203538b0b9a2ad9dfe33acd23ae5a6a149a2591b12a5f22b807b6d7d05a8a8080";
        storageProof[1] = hex"e2a030651f15dd4a2da767e0ddb0cb16b79d7df03d7a81a8644dcd000a7674456cbd01";
        deposit.nonce = 5;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xf4817800f3ed2755a0e67f35e2eab7ce0cb7d18a33962bc41f98f1eb9ab1b000),
            bytes32(0x61e7c946a725218a81677520b6cc53e1d7bc91ee70605587acec4244cc90272b)
        );

        // Populate proof 6
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0d4c4c8a14121232fc4007f741b713fb645400d2eb5a203a3ceffda94b0d34de8a04b3c813fea2ea4fb49cb0624da0fa4af42bb3d13d948495e0520cf7b561874f580a08b92251b0bf565aaeb9236c6ae2fc33e230327828456c5879b5feead26019d0fa04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a01b2645b5ef6d7c2ea61cde01854229586446f1efd88bcd2ed341bda170f721a7a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0c0b8f5ac2b3b9f4aec9f6f561c34ae79c8a09bfbb83c9b06aaaa0e38cd1bccfa80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a08a106988b9d42cf9b8f0b78ac295bb02aaf554744beee89c4cdf40fb77d22a98a07cd33d32a4359662287093f77885de8532b2b006d484908a2c146e2c22f9f66c";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8f1808080a00aa4241791bd906889dd0da533285296b645f0279de87b362c9530262bc5fad780a09f9c3b72b0b91adcf25afe4cdccf5dc6f85505ebed470f2e7ccbcd0c4267ca468080a00ca7f244fb353f3b34d938fab7bc94bb1ca4df7a9d268a28d40a04187aa4348aa0d54f9c40c3a6e8f61bc6a272d034833ab7323a33c786a95e7c097eaa9cee6db3a0023c2a92d7eb4a99982bcb52843e982da5d791e9e8c7a5ea2bf479d5a417a3e68080a0d7629ae444fa8e59a1e873003f1382831b26cfbf498b8935a4cfa751a3dba9cfa035f203538b0b9a2ad9dfe33acd23ae5a6a149a2591b12a5f22b807b6d7d05a8a8080";
        storageProof[1] =
            hex"f85180808080808080a010c569c3182b0233310356d499333bec564e9bdbc3956603ff2d386b903380e0808080808080a051d40da49f0b2058f375e53d37b65cc1bdfd2def6a4f34a377a84f995a478f258080";
        storageProof[2] = hex"e2a0207ef92061fd0ba8e8d220a2a5130393a42c9cf11996c7772f0d5a283fab3a2301";
        deposit.nonce = 6;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d3");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x9d881f0ca5f326f4a0d3d3589b29ecc44acd7328b6c5f0d3c9872fc67730fa00),
            bytes32(0xcf89e2edaf91bdb322be77c51e047dc74ee8bf41e816efdb0b1e1ce89d1378cd)
        );

        // Populate proof 7
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0d4c4c8a14121232fc4007f741b713fb645400d2eb5a203a3ceffda94b0d34de8a04b3c813fea2ea4fb49cb0624da0fa4af42bb3d13d948495e0520cf7b561874f580a08b92251b0bf565aaeb9236c6ae2fc33e230327828456c5879b5feead26019d0fa04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a01b2645b5ef6d7c2ea61cde01854229586446f1efd88bcd2ed341bda170f721a7a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0c0b8f5ac2b3b9f4aec9f6f561c34ae79c8a09bfbb83c9b06aaaa0e38cd1bccfa80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a08a106988b9d42cf9b8f0b78ac295bb02aaf554744beee89c4cdf40fb77d22a98a07cd33d32a4359662287093f77885de8532b2b006d484908a2c146e2c22f9f66c";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8f1808080a00aa4241791bd906889dd0da533285296b645f0279de87b362c9530262bc5fad780a09f9c3b72b0b91adcf25afe4cdccf5dc6f85505ebed470f2e7ccbcd0c4267ca468080a00ca7f244fb353f3b34d938fab7bc94bb1ca4df7a9d268a28d40a04187aa4348aa0d54f9c40c3a6e8f61bc6a272d034833ab7323a33c786a95e7c097eaa9cee6db3a0023c2a92d7eb4a99982bcb52843e982da5d791e9e8c7a5ea2bf479d5a417a3e68080a0d7629ae444fa8e59a1e873003f1382831b26cfbf498b8935a4cfa751a3dba9cfa035f203538b0b9a2ad9dfe33acd23ae5a6a149a2591b12a5f22b807b6d7d05a8a8080";
        storageProof[1] = hex"e2a03e1ec728b89c20261c96918bf1076841a50ec613b7a387876c7dbfa344b9727e01";
        deposit.nonce = 7;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"5932a71200000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x18061deda48b36f68e572bf2f8199ac8b4f47aa16d63b65503b48048508fce00),
            bytes32(0xa7415a7257e99d15070d3dc1a6b628d4ffc1df6b41008fa488fc66a41e4a82d2)
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
        return bytes32(0x6386671c44147130bb31c869a03e77093d112a3f6b6943508c980952e70a7a51);
    }

    /// @inheritdoc ISampleDepositProof
    function getBlockHash() public pure returns (bytes32) {
        return bytes32(0xe63294bf76b407098b7773cb3b63c76d83dca58a96b8f3d07e9af07d9422aaf1);
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
