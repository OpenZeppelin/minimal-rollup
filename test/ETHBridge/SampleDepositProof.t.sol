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
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0dc19e7cdb0dac647039f0ff376555f87a3abdddf18ae1f5766eaa877eb34facba009b8f2b85d2d710d21bcff0db060c44379262e239c923be161ca52a153de2df280a0b68fd204af068de7dbe5ceba150a5d6065592ac2637730d02eacfbfab357e598a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0753f15d13e020c60b344c377e926689c9c98a20babd08ca87b5b524ec4b46efba0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0218a7e3ee36b565722777f71caa3b20adc6cd801cc6938428ef8301c3435c5a280808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0b403b0e47eb30fc8d36373246e4171f84fb909851ea165d9a26acd3aaa4eb6a7a0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8b1a09c2f0e909c78df6cf3d4d1dbba9725b208cb6b31541f062ebd537a1ea1f253ae80808080a0bd68424d57d0e2783cf0fcc30bb2186a0f43cacf4d8865ce9c18f61deb7d2d8d8080a032afffcb18026e99061e9c1c900bfb9d7e63675117d51c2be5bda9089fb80e2e80a00a068c566191b08808f93331baa3c50d4333eb0d9de996975a8ac211a83d0bbfa0656cb66d245b8ab979a986647748f3b66a9db3e52318f36c184d0f3676bcd8448080808080";
        storageProof[1] =
            hex"f85180a003304a8aeb02192b935addb4ae4ef6fc54970d62722ff4abdd0237f3e531139d8080808080a0de68b9cc81aba108c0265507ad01b1b3c830b9365345bdc9ef971489859f539f808080808080808080";
        storageProof[2] = hex"e2a0207b99d702aa11c12c9288f20fa44c3b0580a5d093a01c3b147a75e576c2acd301";
        deposit.nonce = 0;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x68a23db59bedfe3ee7741e80394f17cf48ea56a779b95ee41a87441bfbcbb800),
            bytes32(0xe6b3813ebb86846581f31ebfc306df9e9b419c7c618c87135fae88ee6f5caf7e)
        );

        // Populate proof 1
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0dc19e7cdb0dac647039f0ff376555f87a3abdddf18ae1f5766eaa877eb34facba009b8f2b85d2d710d21bcff0db060c44379262e239c923be161ca52a153de2df280a0b68fd204af068de7dbe5ceba150a5d6065592ac2637730d02eacfbfab357e598a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0753f15d13e020c60b344c377e926689c9c98a20babd08ca87b5b524ec4b46efba0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0218a7e3ee36b565722777f71caa3b20adc6cd801cc6938428ef8301c3435c5a280808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0b403b0e47eb30fc8d36373246e4171f84fb909851ea165d9a26acd3aaa4eb6a7a0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";
        storageProof = new bytes[](4);
        storageProof[0] =
            hex"f8b1a09c2f0e909c78df6cf3d4d1dbba9725b208cb6b31541f062ebd537a1ea1f253ae80808080a0bd68424d57d0e2783cf0fcc30bb2186a0f43cacf4d8865ce9c18f61deb7d2d8d8080a032afffcb18026e99061e9c1c900bfb9d7e63675117d51c2be5bda9089fb80e2e80a00a068c566191b08808f93331baa3c50d4333eb0d9de996975a8ac211a83d0bbfa0656cb66d245b8ab979a986647748f3b66a9db3e52318f36c184d0f3676bcd8448080808080";
        storageProof[1] = hex"e21aa071e3bcfdbcdbe5535fea7f81eaba357f2c176fa274d264b50cdd303b1da9d736";
        storageProof[2] =
            hex"f85180a0c765dfc781f73bbf613f089bda6614ab979284edff814487666e6810e2b23e9980808080a030257d9b8d69c52ccb679214ef623da79ad1917f7b1268658bfc17d3f458548680808080808080808080";
        storageProof[3] = hex"e19f353fffd59ef4893584a6d314a650d8d935c6e53ed11221019745b480077c6f01";
        deposit.nonce = 1;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d2");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xf6baff7116f64fbcaf0e3b3efaf70ebf0d5d76d2bf24e491d1547451decebb00),
            bytes32(0x0f6f508591b34adab7a44fee8f2c303f90ef4cbeb43ed32dc928640b8d2702fa)
        );

        // Populate proof 2
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0dc19e7cdb0dac647039f0ff376555f87a3abdddf18ae1f5766eaa877eb34facba009b8f2b85d2d710d21bcff0db060c44379262e239c923be161ca52a153de2df280a0b68fd204af068de7dbe5ceba150a5d6065592ac2637730d02eacfbfab357e598a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0753f15d13e020c60b344c377e926689c9c98a20babd08ca87b5b524ec4b46efba0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0218a7e3ee36b565722777f71caa3b20adc6cd801cc6938428ef8301c3435c5a280808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0b403b0e47eb30fc8d36373246e4171f84fb909851ea165d9a26acd3aaa4eb6a7a0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8b1a09c2f0e909c78df6cf3d4d1dbba9725b208cb6b31541f062ebd537a1ea1f253ae80808080a0bd68424d57d0e2783cf0fcc30bb2186a0f43cacf4d8865ce9c18f61deb7d2d8d8080a032afffcb18026e99061e9c1c900bfb9d7e63675117d51c2be5bda9089fb80e2e80a00a068c566191b08808f93331baa3c50d4333eb0d9de996975a8ac211a83d0bbfa0656cb66d245b8ab979a986647748f3b66a9db3e52318f36c184d0f3676bcd8448080808080";
        storageProof[1] =
            hex"f8518080a09796dc67e59e42972cafb80cb515e1e10b5f439458d1f4385a7d71de9ce6703580808080a0937fb88e2eb0bfa0b0b34f3d932f9c897b25e06a1e060c7c38453d59065c4ec9808080808080808080";
        storageProof[2] = hex"e2a020db03194b82a069ad1484b6e485745e2308d6d65f9c18859142a9179bfd477c01";
        deposit.nonce = 2;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d3");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x0cbd3d0c70df35d378f5c3440b36bf2b51644d86c594b513a1918742e1c26400),
            bytes32(0xf5266b535af44dc49d49ffdbe43dab4533644f7194492282d68cc8d1d1331e9a)
        );

        // Populate proof 3
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0dc19e7cdb0dac647039f0ff376555f87a3abdddf18ae1f5766eaa877eb34facba009b8f2b85d2d710d21bcff0db060c44379262e239c923be161ca52a153de2df280a0b68fd204af068de7dbe5ceba150a5d6065592ac2637730d02eacfbfab357e598a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0753f15d13e020c60b344c377e926689c9c98a20babd08ca87b5b524ec4b46efba0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0218a7e3ee36b565722777f71caa3b20adc6cd801cc6938428ef8301c3435c5a280808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0b403b0e47eb30fc8d36373246e4171f84fb909851ea165d9a26acd3aaa4eb6a7a0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8b1a09c2f0e909c78df6cf3d4d1dbba9725b208cb6b31541f062ebd537a1ea1f253ae80808080a0bd68424d57d0e2783cf0fcc30bb2186a0f43cacf4d8865ce9c18f61deb7d2d8d8080a032afffcb18026e99061e9c1c900bfb9d7e63675117d51c2be5bda9089fb80e2e80a00a068c566191b08808f93331baa3c50d4333eb0d9de996975a8ac211a83d0bbfa0656cb66d245b8ab979a986647748f3b66a9db3e52318f36c184d0f3676bcd8448080808080";
        storageProof[1] =
            hex"f85180a003304a8aeb02192b935addb4ae4ef6fc54970d62722ff4abdd0237f3e531139d8080808080a0de68b9cc81aba108c0265507ad01b1b3c830b9365345bdc9ef971489859f539f808080808080808080";
        storageProof[2] = hex"e2a020809c5118b1a3769d084b1ad684f813cae421bbbd60745910fad9838b9b8fe901";
        deposit.nonce = 3;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 0;
        deposit.data = bytes(hex"5932a71200000000000000000000000000000000000000000000000000000000000004d2");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xa39b2d84e56307b7c6ac49ccc6c72dd68946c180a282dc90bacd6f59884eae00),
            bytes32(0x9fc40e14c08e343429dd4418fef0bfc49779ede63441ad2bec8dc924ed8dc535)
        );

        // Populate proof 4
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0dc19e7cdb0dac647039f0ff376555f87a3abdddf18ae1f5766eaa877eb34facba009b8f2b85d2d710d21bcff0db060c44379262e239c923be161ca52a153de2df280a0b68fd204af068de7dbe5ceba150a5d6065592ac2637730d02eacfbfab357e598a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0753f15d13e020c60b344c377e926689c9c98a20babd08ca87b5b524ec4b46efba0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0218a7e3ee36b565722777f71caa3b20adc6cd801cc6938428ef8301c3435c5a280808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0b403b0e47eb30fc8d36373246e4171f84fb909851ea165d9a26acd3aaa4eb6a7a0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8b1a09c2f0e909c78df6cf3d4d1dbba9725b208cb6b31541f062ebd537a1ea1f253ae80808080a0bd68424d57d0e2783cf0fcc30bb2186a0f43cacf4d8865ce9c18f61deb7d2d8d8080a032afffcb18026e99061e9c1c900bfb9d7e63675117d51c2be5bda9089fb80e2e80a00a068c566191b08808f93331baa3c50d4333eb0d9de996975a8ac211a83d0bbfa0656cb66d245b8ab979a986647748f3b66a9db3e52318f36c184d0f3676bcd8448080808080";
        storageProof[1] = hex"e2a0324580bb2d05790def716ceebb5c77774e0e9d7ec38f4ed6080b71de2a28b4e301";
        deposit.nonce = 4;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xa59902ea3e6c872abf55a7d5ec51126694c678287c383ebf63fe82bacfd7eb00),
            bytes32(0x7d8ee09f38733cf70c350eb54348a0bc217973bc890aa2f996d99cdd2057b241)
        );

        // Populate proof 5
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0dc19e7cdb0dac647039f0ff376555f87a3abdddf18ae1f5766eaa877eb34facba009b8f2b85d2d710d21bcff0db060c44379262e239c923be161ca52a153de2df280a0b68fd204af068de7dbe5ceba150a5d6065592ac2637730d02eacfbfab357e598a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0753f15d13e020c60b344c377e926689c9c98a20babd08ca87b5b524ec4b46efba0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0218a7e3ee36b565722777f71caa3b20adc6cd801cc6938428ef8301c3435c5a280808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0b403b0e47eb30fc8d36373246e4171f84fb909851ea165d9a26acd3aaa4eb6a7a0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";
        storageProof = new bytes[](4);
        storageProof[0] =
            hex"f8b1a09c2f0e909c78df6cf3d4d1dbba9725b208cb6b31541f062ebd537a1ea1f253ae80808080a0bd68424d57d0e2783cf0fcc30bb2186a0f43cacf4d8865ce9c18f61deb7d2d8d8080a032afffcb18026e99061e9c1c900bfb9d7e63675117d51c2be5bda9089fb80e2e80a00a068c566191b08808f93331baa3c50d4333eb0d9de996975a8ac211a83d0bbfa0656cb66d245b8ab979a986647748f3b66a9db3e52318f36c184d0f3676bcd8448080808080";
        storageProof[1] = hex"e21aa071e3bcfdbcdbe5535fea7f81eaba357f2c176fa274d264b50cdd303b1da9d736";
        storageProof[2] =
            hex"f85180a0c765dfc781f73bbf613f089bda6614ab979284edff814487666e6810e2b23e9980808080a030257d9b8d69c52ccb679214ef623da79ad1917f7b1268658bfc17d3f458548680808080808080808080";
        storageProof[3] = hex"e19f3d508a8e4ec4e280bb805727204a8f3a3183a0dbe566c2f74eb4e7c33256f101";
        deposit.nonce = 5;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d2");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xc4ce736c83cba1802720ae14d487384e48242e7a947177c0702678ed72a19600),
            bytes32(0x6bbf9df93a9ff9b520264b3f6305f0dd749047107e448ae73f95ab7f25f12da8)
        );

        // Populate proof 6
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0dc19e7cdb0dac647039f0ff376555f87a3abdddf18ae1f5766eaa877eb34facba009b8f2b85d2d710d21bcff0db060c44379262e239c923be161ca52a153de2df280a0b68fd204af068de7dbe5ceba150a5d6065592ac2637730d02eacfbfab357e598a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0753f15d13e020c60b344c377e926689c9c98a20babd08ca87b5b524ec4b46efba0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0218a7e3ee36b565722777f71caa3b20adc6cd801cc6938428ef8301c3435c5a280808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0b403b0e47eb30fc8d36373246e4171f84fb909851ea165d9a26acd3aaa4eb6a7a0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";
        storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8b1a09c2f0e909c78df6cf3d4d1dbba9725b208cb6b31541f062ebd537a1ea1f253ae80808080a0bd68424d57d0e2783cf0fcc30bb2186a0f43cacf4d8865ce9c18f61deb7d2d8d8080a032afffcb18026e99061e9c1c900bfb9d7e63675117d51c2be5bda9089fb80e2e80a00a068c566191b08808f93331baa3c50d4333eb0d9de996975a8ac211a83d0bbfa0656cb66d245b8ab979a986647748f3b66a9db3e52318f36c184d0f3676bcd8448080808080";
        storageProof[1] =
            hex"f8518080a09796dc67e59e42972cafb80cb515e1e10b5f439458d1f4385a7d71de9ce6703580808080a0937fb88e2eb0bfa0b0b34f3d932f9c897b25e06a1e060c7c38453d59065c4ec9808080808080808080";
        storageProof[2] = hex"e2a020bd6b3dc06a40369369a3972491324f41477588b8818ba8a6434b8d484bf92f01";
        deposit.nonce = 6;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"9b28f6fb00000000000000000000000000000000000000000000000000000000000004d3");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x81a46546d510ad7c41de08e5521e5b3bf6f4635a7ec7e8a471f3f579f371f100),
            bytes32(0xe3ffe1b432a5bccb7515e15fb1cfe8e2d76a98d8ee4a2d2d0b6b912fa8d61f9f)
        );

        // Populate proof 7
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0dc19e7cdb0dac647039f0ff376555f87a3abdddf18ae1f5766eaa877eb34facba009b8f2b85d2d710d21bcff0db060c44379262e239c923be161ca52a153de2df280a0b68fd204af068de7dbe5ceba150a5d6065592ac2637730d02eacfbfab357e598a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0753f15d13e020c60b344c377e926689c9c98a20babd08ca87b5b524ec4b46efba0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a0218a7e3ee36b565722777f71caa3b20adc6cd801cc6938428ef8301c3435c5a280808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0b403b0e47eb30fc8d36373246e4171f84fb909851ea165d9a26acd3aaa4eb6a7a0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f8b1a09c2f0e909c78df6cf3d4d1dbba9725b208cb6b31541f062ebd537a1ea1f253ae80808080a0bd68424d57d0e2783cf0fcc30bb2186a0f43cacf4d8865ce9c18f61deb7d2d8d8080a032afffcb18026e99061e9c1c900bfb9d7e63675117d51c2be5bda9089fb80e2e80a00a068c566191b08808f93331baa3c50d4333eb0d9de996975a8ac211a83d0bbfa0656cb66d245b8ab979a986647748f3b66a9db3e52318f36c184d0f3676bcd8448080808080";
        storageProof[1] = hex"e2a03bbc4373182852e4206abd4813b56b0a7e4ad887d5fb76a8fa255ca1892f076b01";
        deposit.nonce = 7;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"5932a71200000000000000000000000000000000000000000000000000000000000004d2");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0x9fcaf62e4b991c338e668c11891dbcd8242c349ba6f1cbcd7bbcf5ee5cd5f000),
            bytes32(0xb4d5168a51f3b0ed2dce02c95be834c76d52a0befce9cb26b97c5c0bb778f424)
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
        return bytes32(0x45990bde885ef3382f7d4c66d94d2b887897244ccff2c2ce784b7494e7316d2f);
    }

    /// @inheritdoc ISampleDepositProof
    function getBlockHash() public pure returns (bytes32) {
        return bytes32(0x1bda58dcab280fddde2d12eb2b3932ab30b0a400206ab92516f295a24848922b);
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
