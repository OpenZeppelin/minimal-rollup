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
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a04f9b3074be6c1048a52625a98244b225239aeb72c6fe9a8b84295c54c11f7711a0bba366e6a2f8ee0148ec2fb8c8f612f97c5c013c92997f187dec28eab359bf9980a0ad32814d04dc4f3d2d4837d098843cdb23d3b2ff2998d68bd3d567c28351f678a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a09016cdf52377ca6d080a61a641119ebe8344e7efa3a347dbaf187d0bc706997ca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0253a8805e504ff1d068e38ce687ee7719d6428467537c6e0a9e380bab6c1e7cc80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a03135b57fa5c3a632d77d047ed9beb7ad2fb10175e0aaca41fbe4de814ed565a5a04c6a820395819646f26663eb133c936140a62bc46c8d408aa765d28abac30b48";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8d180a0c3fd297a8560d746e4780fae27a416a5e164111f3fbdeafed15debeeb6285ffc808080a033bc0bdee3ae72377d806414ce91a661c7113f3b2f536fccf941284eca737bca80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] = hex"e2a0364c1d30c1806da24e88e0a857e4520f5db1cf68dd0062081a0e4228f77539b901";
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
            bytes32(0x1e44da7772dd4f24931c42fcb5e68c8673f9b7560b8fdede360903011ed09000),
            bytes32(0xc86deb495f158920b402152458621f9131f535c7fbd3e0b5ec852b7aa1baae68)
        );

        // Populate proof 1
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a04f9b3074be6c1048a52625a98244b225239aeb72c6fe9a8b84295c54c11f7711a0bba366e6a2f8ee0148ec2fb8c8f612f97c5c013c92997f187dec28eab359bf9980a0ad32814d04dc4f3d2d4837d098843cdb23d3b2ff2998d68bd3d567c28351f678a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a09016cdf52377ca6d080a61a641119ebe8344e7efa3a347dbaf187d0bc706997ca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0253a8805e504ff1d068e38ce687ee7719d6428467537c6e0a9e380bab6c1e7cc80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a03135b57fa5c3a632d77d047ed9beb7ad2fb10175e0aaca41fbe4de814ed565a5a04c6a820395819646f26663eb133c936140a62bc46c8d408aa765d28abac30b48";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8d180a0c3fd297a8560d746e4780fae27a416a5e164111f3fbdeafed15debeeb6285ffc808080a033bc0bdee3ae72377d806414ce91a661c7113f3b2f536fccf941284eca737bca80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] =
            hex"f871a0ac0ab8236b89edcddfa59445ed79c6a0df2f3454ff2321552274c70e685a3bb680808080808080a010237a96531b9158ff3aafaee82ea5f130f545caf960b74cd6dae12d8224117c80a0b8032e9de4472649cdc452eb03ece2d845db06b5d219ffd1781c123e8a309cb2808080808080";
        storageProof[2] = hex"e2a020f0cfec76005c392ac1714cd5aa39c2adcef238b320f94b230b6a05b62c6ca701";
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
            bytes32(0xf34fc2f940056cd918eb9bf82cd15c84d8a830825f6c9f2bca244a3d5ac72b00),
            bytes32(0xe8acde42a830761087678a01dba05c3e1971428a97701e702f6e987c16b04a8c)
        );

        // Populate proof 2
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a04f9b3074be6c1048a52625a98244b225239aeb72c6fe9a8b84295c54c11f7711a0bba366e6a2f8ee0148ec2fb8c8f612f97c5c013c92997f187dec28eab359bf9980a0ad32814d04dc4f3d2d4837d098843cdb23d3b2ff2998d68bd3d567c28351f678a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a09016cdf52377ca6d080a61a641119ebe8344e7efa3a347dbaf187d0bc706997ca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0253a8805e504ff1d068e38ce687ee7719d6428467537c6e0a9e380bab6c1e7cc80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a03135b57fa5c3a632d77d047ed9beb7ad2fb10175e0aaca41fbe4de814ed565a5a04c6a820395819646f26663eb133c936140a62bc46c8d408aa765d28abac30b48";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8d180a0c3fd297a8560d746e4780fae27a416a5e164111f3fbdeafed15debeeb6285ffc808080a033bc0bdee3ae72377d806414ce91a661c7113f3b2f536fccf941284eca737bca80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] = hex"e2a03e3c562fa07f1399eaa3fdf0901cecf3a643b9dc7aad8866bc2a293ca1d2407d01";
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
            bytes32(0x0c4fa7982c13d730d556d27f148fb90e14475cc99fc12cee90bfc13805f1a300),
            bytes32(0x933f16b0513699dbe027e15c3ccb47324706b25da8a4a240b2de5e53c8345a9f)
        );

        // Populate proof 3
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a04f9b3074be6c1048a52625a98244b225239aeb72c6fe9a8b84295c54c11f7711a0bba366e6a2f8ee0148ec2fb8c8f612f97c5c013c92997f187dec28eab359bf9980a0ad32814d04dc4f3d2d4837d098843cdb23d3b2ff2998d68bd3d567c28351f678a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a09016cdf52377ca6d080a61a641119ebe8344e7efa3a347dbaf187d0bc706997ca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0253a8805e504ff1d068e38ce687ee7719d6428467537c6e0a9e380bab6c1e7cc80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a03135b57fa5c3a632d77d047ed9beb7ad2fb10175e0aaca41fbe4de814ed565a5a04c6a820395819646f26663eb133c936140a62bc46c8d408aa765d28abac30b48";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8d180a0c3fd297a8560d746e4780fae27a416a5e164111f3fbdeafed15debeeb6285ffc808080a033bc0bdee3ae72377d806414ce91a661c7113f3b2f536fccf941284eca737bca80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] = hex"e2a03298559ee3a1fc13f5d90911d10cd3f6e023dafdaab83dad6b553176288219d701";
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
            bytes32(0x3362ef917f8cdd3ed09245590a73210baa4e415d01b89c4b96c43bc0c377ae00),
            bytes32(0xa8ccb6cd36b998e6c2f35a4053fbbb361366f871605cfc6f3400d7303abcdb0b)
        );

        // Populate proof 4
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a04f9b3074be6c1048a52625a98244b225239aeb72c6fe9a8b84295c54c11f7711a0bba366e6a2f8ee0148ec2fb8c8f612f97c5c013c92997f187dec28eab359bf9980a0ad32814d04dc4f3d2d4837d098843cdb23d3b2ff2998d68bd3d567c28351f678a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a09016cdf52377ca6d080a61a641119ebe8344e7efa3a347dbaf187d0bc706997ca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0253a8805e504ff1d068e38ce687ee7719d6428467537c6e0a9e380bab6c1e7cc80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a03135b57fa5c3a632d77d047ed9beb7ad2fb10175e0aaca41fbe4de814ed565a5a04c6a820395819646f26663eb133c936140a62bc46c8d408aa765d28abac30b48";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8d180a0c3fd297a8560d746e4780fae27a416a5e164111f3fbdeafed15debeeb6285ffc808080a033bc0bdee3ae72377d806414ce91a661c7113f3b2f536fccf941284eca737bca80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] = hex"e2a032f37e04aad6a253fdac683c9702c043edb2517b6ac2c5d1f4991a814fbba2dd01";
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
            bytes32(0xa10efb554b1ce391abb94d39441848daa1bddc7e28530d333cda842d3e4b9400),
            bytes32(0x78d6063dc03515fedcfa706f4ae246707bfe12b4bb0d8f21330bc6b404a3bbec)
        );

        // Populate proof 5
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a04f9b3074be6c1048a52625a98244b225239aeb72c6fe9a8b84295c54c11f7711a0bba366e6a2f8ee0148ec2fb8c8f612f97c5c013c92997f187dec28eab359bf9980a0ad32814d04dc4f3d2d4837d098843cdb23d3b2ff2998d68bd3d567c28351f678a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a09016cdf52377ca6d080a61a641119ebe8344e7efa3a347dbaf187d0bc706997ca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0253a8805e504ff1d068e38ce687ee7719d6428467537c6e0a9e380bab6c1e7cc80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a03135b57fa5c3a632d77d047ed9beb7ad2fb10175e0aaca41fbe4de814ed565a5a04c6a820395819646f26663eb133c936140a62bc46c8d408aa765d28abac30b48";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8d180a0c3fd297a8560d746e4780fae27a416a5e164111f3fbdeafed15debeeb6285ffc808080a033bc0bdee3ae72377d806414ce91a661c7113f3b2f536fccf941284eca737bca80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] = hex"e2a03cad719b28877087569378c8a30b53f1f39801c45c7edd14a58e68cf3a9bd1ab01";
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
            bytes32(0xe8b94839aa2eec31949ad4460fc0629de20e7367ed3b251df3920c8c3aafa600),
            bytes32(0x1d180c134c2410c9e046ec13543ec5350348286669361e3d8f8d518344ed8154)
        );

        // Populate proof 6
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a04f9b3074be6c1048a52625a98244b225239aeb72c6fe9a8b84295c54c11f7711a0bba366e6a2f8ee0148ec2fb8c8f612f97c5c013c92997f187dec28eab359bf9980a0ad32814d04dc4f3d2d4837d098843cdb23d3b2ff2998d68bd3d567c28351f678a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a09016cdf52377ca6d080a61a641119ebe8344e7efa3a347dbaf187d0bc706997ca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0253a8805e504ff1d068e38ce687ee7719d6428467537c6e0a9e380bab6c1e7cc80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a03135b57fa5c3a632d77d047ed9beb7ad2fb10175e0aaca41fbe4de814ed565a5a04c6a820395819646f26663eb133c936140a62bc46c8d408aa765d28abac30b48";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8d180a0c3fd297a8560d746e4780fae27a416a5e164111f3fbdeafed15debeeb6285ffc808080a033bc0bdee3ae72377d806414ce91a661c7113f3b2f536fccf941284eca737bca80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] =
            hex"f871a0ac0ab8236b89edcddfa59445ed79c6a0df2f3454ff2321552274c70e685a3bb680808080808080a010237a96531b9158ff3aafaee82ea5f130f545caf960b74cd6dae12d8224117c80a0b8032e9de4472649cdc452eb03ece2d845db06b5d219ffd1781c123e8a309cb2808080808080";
        storageProof[2] = hex"e2a020da500035aa803b6d4e3cd8ac4209e0c95810b2a3c45513e4d52d3886b9a20a01";
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
            bytes32(0x39a0868654d724a1f040ec71a5a7e73ba7a3c725155db5f0ddc085d76e714000),
            bytes32(0xd69bbbb7f9326f41024cbf37447fa35120732b98dc60b857a5e24c2b5d9597e7)
        );

        // Populate proof 7
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a04f9b3074be6c1048a52625a98244b225239aeb72c6fe9a8b84295c54c11f7711a0bba366e6a2f8ee0148ec2fb8c8f612f97c5c013c92997f187dec28eab359bf9980a0ad32814d04dc4f3d2d4837d098843cdb23d3b2ff2998d68bd3d567c28351f678a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a09016cdf52377ca6d080a61a641119ebe8344e7efa3a347dbaf187d0bc706997ca0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0253a8805e504ff1d068e38ce687ee7719d6428467537c6e0a9e380bab6c1e7cc80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a03135b57fa5c3a632d77d047ed9beb7ad2fb10175e0aaca41fbe4de814ed565a5a04c6a820395819646f26663eb133c936140a62bc46c8d408aa765d28abac30b48";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8d180a0c3fd297a8560d746e4780fae27a416a5e164111f3fbdeafed15debeeb6285ffc808080a033bc0bdee3ae72377d806414ce91a661c7113f3b2f536fccf941284eca737bca80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] =
            hex"f871a0ac0ab8236b89edcddfa59445ed79c6a0df2f3454ff2321552274c70e685a3bb680808080808080a010237a96531b9158ff3aafaee82ea5f130f545caf960b74cd6dae12d8224117c80a0b8032e9de4472649cdc452eb03ece2d845db06b5d219ffd1781c123e8a309cb2808080808080";
        storageProof[2] = hex"e2a020820c5a5abbb0bb050f885a37d26e1d5311b4dcb2e8a2ba48c72de213b00a4301";
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
            bytes32(0xf55995bfd5a36e0f7738ee353ea9757d04379740a8a30cae67006b8f825ef700),
            bytes32(0x0288428c4eaaf77d8195c0169f88f642b43f44955e36ab09d1e1942fe64d0ba9)
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
        return bytes32(0xbf793a27cc4b534fdffda4c380f2cac2d70b3e1f663bdaaa826ede98f5b4790a);
    }

    /// @inheritdoc ISampleDepositProof
    function getBlockHash() public pure returns (bytes32) {
        return bytes32(0xfa0e2ded914764f5f2bd4e6be751a6febe78f98b51d07aae71cf5b845276cfa7);
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
