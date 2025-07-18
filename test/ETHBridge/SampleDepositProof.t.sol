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
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a00117adb63c224a950ca594ebe930ceb41b4b3997fecc58a16b16bddd9079b484a0929dafc59ad0ec3d26c6ec622c1656b88ec49f2673e5cb5ca4ce2bf7d6e24e5a80a01ac8825b988bd916f72d71b91ad70b76aeb2281492b14ed531dadb500ed7e7d6a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0ef39bb6b9f54457d157cafa1289da63fb5059a37a91c6bb1e5f87450151936f9a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a04efc72fb79edd49b26fe93702999204c45d096384fd7d3b65224b358790cc58080808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0e7eefd8ba04e92d266fe2bd0e882a0aae1255659c02965110a693d25a3a0cc07a0bf80f96ed976bf2eaca63f8aa6153894b8c450b2bf2ac4762f1252d95b690ca9";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8d180a01eaa57f8237dd40a27df7db13cce1c44a6f8f5a24b2ee74f25563acae0e245e3808080a0b4231c7619022db6faebc81fb9be2742dd5574bd955b77914b2a1e6e17cb760c80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] = hex"e2a0364c1d30c1806da24e88e0a857e4520f5db1cf68dd0062081a0e4228f77539b901";
        deposit.nonce = 0;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0x0000000000000000000000000000000000000000);
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
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a00117adb63c224a950ca594ebe930ceb41b4b3997fecc58a16b16bddd9079b484a0929dafc59ad0ec3d26c6ec622c1656b88ec49f2673e5cb5ca4ce2bf7d6e24e5a80a01ac8825b988bd916f72d71b91ad70b76aeb2281492b14ed531dadb500ed7e7d6a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0ef39bb6b9f54457d157cafa1289da63fb5059a37a91c6bb1e5f87450151936f9a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a04efc72fb79edd49b26fe93702999204c45d096384fd7d3b65224b358790cc58080808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0e7eefd8ba04e92d266fe2bd0e882a0aae1255659c02965110a693d25a3a0cc07a0bf80f96ed976bf2eaca63f8aa6153894b8c450b2bf2ac4762f1252d95b690ca9";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8d180a01eaa57f8237dd40a27df7db13cce1c44a6f8f5a24b2ee74f25563acae0e245e3808080a0b4231c7619022db6faebc81fb9be2742dd5574bd955b77914b2a1e6e17cb760c80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] =
            hex"f871a0ac0ab8236b89edcddfa59445ed79c6a0df2f3454ff2321552274c70e685a3bb680808080808080a010237a96531b9158ff3aafaee82ea5f130f545caf960b74cd6dae12d8224117c80a0b8032e9de4472649cdc452eb03ece2d845db06b5d219ffd1781c123e8a309cb2808080808080";
        storageProof[2] = hex"e2a020f0cfec76005c392ac1714cd5aa39c2adcef238b320f94b230b6a05b62c6ca701";
        deposit.nonce = 1;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0x0000000000000000000000000000000000000000);
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
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a00117adb63c224a950ca594ebe930ceb41b4b3997fecc58a16b16bddd9079b484a0929dafc59ad0ec3d26c6ec622c1656b88ec49f2673e5cb5ca4ce2bf7d6e24e5a80a01ac8825b988bd916f72d71b91ad70b76aeb2281492b14ed531dadb500ed7e7d6a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0ef39bb6b9f54457d157cafa1289da63fb5059a37a91c6bb1e5f87450151936f9a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a04efc72fb79edd49b26fe93702999204c45d096384fd7d3b65224b358790cc58080808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0e7eefd8ba04e92d266fe2bd0e882a0aae1255659c02965110a693d25a3a0cc07a0bf80f96ed976bf2eaca63f8aa6153894b8c450b2bf2ac4762f1252d95b690ca9";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8d180a01eaa57f8237dd40a27df7db13cce1c44a6f8f5a24b2ee74f25563acae0e245e3808080a0b4231c7619022db6faebc81fb9be2742dd5574bd955b77914b2a1e6e17cb760c80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] =
            hex"f85180808080808080808080808080a096ab9669b0848d89de29b11263945b269f24709d388bcfd8d7f9eaac2e4cce51a0cbb3ff216a0f71d93d13dd4f8dc6481e5d1f9030e457abedae6f673ced973f968080";
        storageProof[2] = hex"e2a0203c562fa07f1399eaa3fdf0901cecf3a643b9dc7aad8866bc2a293ca1d2407d01";
        deposit.nonce = 2;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d3");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0x0000000000000000000000000000000000000000);
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
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a00117adb63c224a950ca594ebe930ceb41b4b3997fecc58a16b16bddd9079b484a0929dafc59ad0ec3d26c6ec622c1656b88ec49f2673e5cb5ca4ce2bf7d6e24e5a80a01ac8825b988bd916f72d71b91ad70b76aeb2281492b14ed531dadb500ed7e7d6a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0ef39bb6b9f54457d157cafa1289da63fb5059a37a91c6bb1e5f87450151936f9a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a04efc72fb79edd49b26fe93702999204c45d096384fd7d3b65224b358790cc58080808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0e7eefd8ba04e92d266fe2bd0e882a0aae1255659c02965110a693d25a3a0cc07a0bf80f96ed976bf2eaca63f8aa6153894b8c450b2bf2ac4762f1252d95b690ca9";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8d180a01eaa57f8237dd40a27df7db13cce1c44a6f8f5a24b2ee74f25563acae0e245e3808080a0b4231c7619022db6faebc81fb9be2742dd5574bd955b77914b2a1e6e17cb760c80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] = hex"e2a03298559ee3a1fc13f5d90911d10cd3f6e023dafdaab83dad6b553176288219d701";
        deposit.nonce = 3;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"5932a71200000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0x0000000000000000000000000000000000000000);
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
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a00117adb63c224a950ca594ebe930ceb41b4b3997fecc58a16b16bddd9079b484a0929dafc59ad0ec3d26c6ec622c1656b88ec49f2673e5cb5ca4ce2bf7d6e24e5a80a01ac8825b988bd916f72d71b91ad70b76aeb2281492b14ed531dadb500ed7e7d6a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0ef39bb6b9f54457d157cafa1289da63fb5059a37a91c6bb1e5f87450151936f9a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a04efc72fb79edd49b26fe93702999204c45d096384fd7d3b65224b358790cc58080808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0e7eefd8ba04e92d266fe2bd0e882a0aae1255659c02965110a693d25a3a0cc07a0bf80f96ed976bf2eaca63f8aa6153894b8c450b2bf2ac4762f1252d95b690ca9";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8d180a01eaa57f8237dd40a27df7db13cce1c44a6f8f5a24b2ee74f25563acae0e245e3808080a0b4231c7619022db6faebc81fb9be2742dd5574bd955b77914b2a1e6e17cb760c80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] = hex"e2a032f37e04aad6a253fdac683c9702c043edb2517b6ac2c5d1f4991a814fbba2dd01";
        deposit.nonce = 4;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0x0000000000000000000000000000000000000000);
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
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a00117adb63c224a950ca594ebe930ceb41b4b3997fecc58a16b16bddd9079b484a0929dafc59ad0ec3d26c6ec622c1656b88ec49f2673e5cb5ca4ce2bf7d6e24e5a80a01ac8825b988bd916f72d71b91ad70b76aeb2281492b14ed531dadb500ed7e7d6a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0ef39bb6b9f54457d157cafa1289da63fb5059a37a91c6bb1e5f87450151936f9a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a04efc72fb79edd49b26fe93702999204c45d096384fd7d3b65224b358790cc58080808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0e7eefd8ba04e92d266fe2bd0e882a0aae1255659c02965110a693d25a3a0cc07a0bf80f96ed976bf2eaca63f8aa6153894b8c450b2bf2ac4762f1252d95b690ca9";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8d180a01eaa57f8237dd40a27df7db13cce1c44a6f8f5a24b2ee74f25563acae0e245e3808080a0b4231c7619022db6faebc81fb9be2742dd5574bd955b77914b2a1e6e17cb760c80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] =
            hex"f851808080808080a000aa4cad156beedbb925a97c52432b1a0aaa0ba154e6293c5e98d303695034fa8080808080a06028db865464ee19c0c3e330adb214412c80cb6e081b03948ed681079ff0aaba80808080";
        storageProof[2] = hex"e2a020ad719b28877087569378c8a30b53f1f39801c45c7edd14a58e68cf3a9bd1ab01";
        deposit.nonce = 5;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0x0000000000000000000000000000000000000000);
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
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a00117adb63c224a950ca594ebe930ceb41b4b3997fecc58a16b16bddd9079b484a0929dafc59ad0ec3d26c6ec622c1656b88ec49f2673e5cb5ca4ce2bf7d6e24e5a80a01ac8825b988bd916f72d71b91ad70b76aeb2281492b14ed531dadb500ed7e7d6a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0ef39bb6b9f54457d157cafa1289da63fb5059a37a91c6bb1e5f87450151936f9a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a04efc72fb79edd49b26fe93702999204c45d096384fd7d3b65224b358790cc58080808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0e7eefd8ba04e92d266fe2bd0e882a0aae1255659c02965110a693d25a3a0cc07a0bf80f96ed976bf2eaca63f8aa6153894b8c450b2bf2ac4762f1252d95b690ca9";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8d180a01eaa57f8237dd40a27df7db13cce1c44a6f8f5a24b2ee74f25563acae0e245e3808080a0b4231c7619022db6faebc81fb9be2742dd5574bd955b77914b2a1e6e17cb760c80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] =
            hex"f871a0ac0ab8236b89edcddfa59445ed79c6a0df2f3454ff2321552274c70e685a3bb680808080808080a010237a96531b9158ff3aafaee82ea5f130f545caf960b74cd6dae12d8224117c80a0b8032e9de4472649cdc452eb03ece2d845db06b5d219ffd1781c123e8a309cb2808080808080";
        storageProof[2] = hex"e2a020da500035aa803b6d4e3cd8ac4209e0c95810b2a3c45513e4d52d3886b9a20a01";
        deposit.nonce = 6;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d3");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0x0000000000000000000000000000000000000000);
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
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a00117adb63c224a950ca594ebe930ceb41b4b3997fecc58a16b16bddd9079b484a0929dafc59ad0ec3d26c6ec622c1656b88ec49f2673e5cb5ca4ce2bf7d6e24e5a80a01ac8825b988bd916f72d71b91ad70b76aeb2281492b14ed531dadb500ed7e7d6a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0ef39bb6b9f54457d157cafa1289da63fb5059a37a91c6bb1e5f87450151936f9a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a04efc72fb79edd49b26fe93702999204c45d096384fd7d3b65224b358790cc58080808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0e7eefd8ba04e92d266fe2bd0e882a0aae1255659c02965110a693d25a3a0cc07a0bf80f96ed976bf2eaca63f8aa6153894b8c450b2bf2ac4762f1252d95b690ca9";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8d180a01eaa57f8237dd40a27df7db13cce1c44a6f8f5a24b2ee74f25563acae0e245e3808080a0b4231c7619022db6faebc81fb9be2742dd5574bd955b77914b2a1e6e17cb760c80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] =
            hex"f871a0ac0ab8236b89edcddfa59445ed79c6a0df2f3454ff2321552274c70e685a3bb680808080808080a010237a96531b9158ff3aafaee82ea5f130f545caf960b74cd6dae12d8224117c80a0b8032e9de4472649cdc452eb03ece2d845db06b5d219ffd1781c123e8a309cb2808080808080";
        storageProof[2] = hex"e2a020820c5a5abbb0bb050f885a37d26e1d5311b4dcb2e8a2ba48c72de213b00a4301";
        deposit.nonce = 7;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"5932a71200000000000000000000000000000000000000000000000000000000000004d2");
        deposit.context = bytes(hex"");
        deposit.canceler = address(0x0000000000000000000000000000000000000000);
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xf55995bfd5a36e0f7738ee353ea9757d04379740a8a30cae67006b8f825ef700),
            bytes32(0x0288428c4eaaf77d8195c0169f88f642b43f44955e36ab09d1e1942fe64d0ba9)
        );

        // Populate proof 8
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a00117adb63c224a950ca594ebe930ceb41b4b3997fecc58a16b16bddd9079b484a0929dafc59ad0ec3d26c6ec622c1656b88ec49f2673e5cb5ca4ce2bf7d6e24e5a80a01ac8825b988bd916f72d71b91ad70b76aeb2281492b14ed531dadb500ed7e7d6a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0ef39bb6b9f54457d157cafa1289da63fb5059a37a91c6bb1e5f87450151936f9a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a04efc72fb79edd49b26fe93702999204c45d096384fd7d3b65224b358790cc58080808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0e7eefd8ba04e92d266fe2bd0e882a0aae1255659c02965110a693d25a3a0cc07a0bf80f96ed976bf2eaca63f8aa6153894b8c450b2bf2ac4762f1252d95b690ca9";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8d180a01eaa57f8237dd40a27df7db13cce1c44a6f8f5a24b2ee74f25563acae0e245e3808080a0b4231c7619022db6faebc81fb9be2742dd5574bd955b77914b2a1e6e17cb760c80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] =
            hex"f85180808080808080808080808080a096ab9669b0848d89de29b11263945b269f24709d388bcfd8d7f9eaac2e4cce51a0cbb3ff216a0f71d93d13dd4f8dc6481e5d1f9030e457abedae6f673ced973f968080";
        storageProof[2] = hex"e2a020fa070d8cbdb614c3ff4e3c16bc142b171e5212a55605ffbcacf60cb4ae268101";
        deposit.nonce = 8;
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
            bytes32(0x140e4f89503b61ca661d18021230c261f47dd8ef1c8fbe296f23878819bd5800),
            bytes32(0x90e0b910cfc241e3a56547d04f545960aa8f06d4be88c0831b5af96a52e71eba)
        );

        // Populate proof 9
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a00117adb63c224a950ca594ebe930ceb41b4b3997fecc58a16b16bddd9079b484a0929dafc59ad0ec3d26c6ec622c1656b88ec49f2673e5cb5ca4ce2bf7d6e24e5a80a01ac8825b988bd916f72d71b91ad70b76aeb2281492b14ed531dadb500ed7e7d6a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0ef39bb6b9f54457d157cafa1289da63fb5059a37a91c6bb1e5f87450151936f9a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a04efc72fb79edd49b26fe93702999204c45d096384fd7d3b65224b358790cc58080808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0e7eefd8ba04e92d266fe2bd0e882a0aae1255659c02965110a693d25a3a0cc07a0bf80f96ed976bf2eaca63f8aa6153894b8c450b2bf2ac4762f1252d95b690ca9";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8d180a01eaa57f8237dd40a27df7db13cce1c44a6f8f5a24b2ee74f25563acae0e245e3808080a0b4231c7619022db6faebc81fb9be2742dd5574bd955b77914b2a1e6e17cb760c80a008da7afef899990836d7474b37dba4be023feff40beef8598837f46dd285be8da03032f295e4a1ec28653b9412977b641edde37ab05622bd1e70296ff9d43981b980a0277ced4f9566e5d05fe2c8ffe2aa09e8d4d679218e0f545f35ae5c57d77257b280a06465f9f60adda0e80794baebb3431f108a436c0958858df32ea220d788a9e1e580808080";
        storageProof[1] =
            hex"f851808080808080a000aa4cad156beedbb925a97c52432b1a0aaa0ba154e6293c5e98d303695034fa8080808080a06028db865464ee19c0c3e330adb214412c80cb6e081b03948ed681079ff0aaba80808080";
        storageProof[2] = hex"e2a020c9322c2b5c4336b2464332ae3f2ddbe2ae221eb1043756167d4a38d60aee9901";
        deposit.nonce = 9;
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
            bytes32(0xef84d975bd035ebb480958cc639ddc548e17d1a94d2b0f7e97d76344db620200),
            bytes32(0xfb0fdb65b68fec358045bdf860b18c8118544fa574d24b3429ea12286c8979db)
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
        return bytes32(0x7cde9ce72e2121679400a66da043475a6919809e29f59a443cca26e2867d9554);
    }

    /// @inheritdoc ISampleDepositProof
    function getBlockHash() public pure returns (bytes32) {
        return bytes32(0x3b457a32611e0908dc8b5f9ddec02bf665a5db16fd305f2686c754e3809951a3);
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
