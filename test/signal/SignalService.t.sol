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

contract BaseStateTest is BaseState {
    function test_yo() public {
        console.log("ROLLUP OPERATOR", rollupOperator);
    }
}

contract SendL1SignalState is BaseState {
    uint256 public value = 0x1234;

    function setUp() public virtual override {
        super.setUp();
    }
}

contract SendL1SignalTest is SendL1SignalState {
    function test_sendL1Signal() public {
        console.log("L1signalService", address(L1signalService));
        console.log("L2signalService", address(L2signalService));
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        bytes32 slot = L1signalService.sendSignal(keccak256(abi.encode(value)));
        bytes32 signal = keccak256(abi.encode(value));
        console.logBytes32(keccak256(abi.encode(value)));
        console.logBytes32(slot);
        bytes[] memory storageProof = new bytes[](2);

        storageProof[0] =
            "0xf85180808080a015ae32d5986f7e597e8a4db519e6640db0eeb8271f30c7691dc58cd99b9cae8d80a0a160b00940ca7a9c5095328a15b5db8f3df8a2fb5044c2a1d68881196bc70e1580808080808080808080";
        storageProof[1] =
            "0xf843a0354ada5ea82feea206d357f61e2debe1375f3ba29fb1583a75918c3e84924563a1a0e321d900f3fd366734e2d071e30949ded20c27fd638f1a059390091c643b62c5";

        bytes[] memory accountProof = new bytes[](5);
        accountProof[0] =
            "0xf90211a037cdb9272b0112766e3562924388770df6e8608f51c713f47d5b592820dde371a0ddfc5937e63e0489d1daf51495eb9b1bba01b4c673113a4b872f2aed02200c82a0473ecf8a7e36a829e75039a3b055e51b8332cbf03324ab4af2066bbd6fbf0021a0bbda34753d7aa6c38e603f360244e8f59611921d9e1f128372fec0d586d4f9e0a0677aeed5565b2093a04425b55eb53456b2cc4fbfe929f183aebc25f465547ea3a095ba84feab08bb5aa85ace58fe68115f7c2776c93c012b8a00203b443e7a466aa0e823850f50bf72baae9d1733a36a444ab65d0a6faaba404f0583ce0ca4dad92da0f7a00cbe7d4b30b11faea3ae61b7f1f2b315b61d9f6bd68bfe587ad0eeceb721a0252a4736667be7f93ce1428a4a39723d779d8046cfdd9d436b45d77babad2373a0487e2cc3d9ce9f6fc7ed4277a5e0f8db204b93ba7f7e53872377fea71a06bc8ba0203d26456312bbc4da5cd293b75b840fc5045e493d6f904d180823ec22bfed8ea0fa61ca035ccb47e7291863645a765dca791154f3410079c7c6a68c5adc459dd2a06fc2d754e304c48ce6a517753c62b1a9c1d5925b89707486d7fc08919e0a94eca07b1c54f15e299bd58bdfef9741538c7828b5d7d11a489f9c20d052b3471df475a0e9c2f62efd1e463701250d670599b37f9e5b0695f5ac12a072a8850cd95249b8a057f53e45b06da93c04ca14eb8b0068a25f037807cc28222eb6e81d468144dcc780";
        accountProof[1] =
            "0xf90211a0a9317a59365ca09cefcd384018696590afffc432e35a97e8f85aa48907bf3247a0e0bc229254ce7a6a736c3953e570ab18b4a7f5f2a9aa3c3057b5f17d250a1cada0a2484ec8884dbe0cf24ece99d67df0d1fe78992d67cc777636a817cb2ef205aaa012b78d4078c607747f06bb88bd08f839eaae0e3ac6854e5f65867d4f78abb84ea0caa2d06f2c90de2ea7088edc6c1722d21551cca5b5bfa009a48a2b7176f66758a013f8d617b6a734da9235b6ac80bdd7aeaff6120c39aa223638d88f22d4ba4007a002055c6400e0ec3440a8bb8fdfd7d6b6c57b7bf83e37d7e4e983d416fdd8314ea04b1cca9eb3e47e805e7f4c80671a9fcd589fd6ddbe1790c3f3e177e8ede01b9ea070c3815efb23b986018089e009a38e6238b8850b3efd33831913ca6fa9240249a0556a8c3366ba083fe77787480ea6859d61f8fe721cc5df6f158294e7fc23a98ba0b2b3cd9f1e46eb583a6185d9a96b4e80125e3d75e6191fdcf684892ef52935cba05e0b4b9c6b6fd73ff5228cfe43518fa597cc797db18c3e930451d74c2c84ad92a034d9ff0fee6c929424e52268dedbc596d10786e909c5a68d6466c2aba17387cea07484d5e44b6ee6b10000708c37e035b42b818475620f9316beffc46531d1eebfa030c8a283adccf2742272563cd3d6710c89ba21eac0118bf5310cfb231bcca77fa04bae8558d2385b8d3bc6e6ede20bdbc5dbb0b5384c316ba8985682f88d2e506d80";
        accountProof[2] =
            "0xf901d1a099ae1bbb2d9d0774e3753cfa37a02d5177077759762f481f0204382e3f86d8e1a06cc4e1093c86cb3d16a163f8e80d32561fd91928c9d27dfabc6d9b35d790bf4a80a023b6e2f9ab0919d5940639d12201b843310ef9c57df95ba21d0d456d1374548da035d0766357755d2718274a2d32b698ca45f6c070af83438a2255f0ced7d3433ba0e1ac3d4f12c335fefd48c1cdd3d68ad30ba15cd394e6df6f86899b9e331dcb47a054403d0dd5fbcd2f90d655efc840e88d8f5ab0c625feff88c8065f94cd75b632a0eb9437de6315224b73c42a24c59ca1b528c01d1ee5fbf88c542a9bc545e0b7f4a01807e1920e595b3d15a27f7d5b7ac06b7164b527741a839f288f9a1bb6cefe37a0d26de39c72431c00d164ff63f8653578edf1e3485ca50a22a1113960ae2968fa80a09bc883a21e01f119fdf6c72d7132a57097d8ad846b70ede46c970500a8762d34a03467446762aedf17213f54c6905fa2c6d6ed13d36aea60a891d700fd11db9918a02e17bf1e5c35ca854ed4928b2341f5191d685bd20295486a75acf09127b5264ba0a7e50e409da0eea28caf646193331fc615aacbf995747cb06562a52c76a8a64ea0f6a2135f2efb0f9c136b7c3891083d104b7703423e3262fa5df2d786fe2ac35180";
        accountProof[3] =
            "0xf871808080808080a08da62593768ad09f2ff21d6598833d0cd4b71858061d8cba72dd8125ffea10008080808080a0acd636f87ea79819be2cc4a0ae85e876ab9a9f4ed32de9048bab2e926d25df388080a0acd422dd5c403b19cb8dc0ddd16e8176cfaeeab1f9a186a615980e8be1d3638480";
        accountProof[4] =
            "0xf8689f2059e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a04112cb836908f39193de897177c47c54194a033116b0757b309946d9e456be3ba0f749525190000b76b179fd38e046a5f840becae1a99f31562d245553eec4893b";

        ISignalService.SignalProof memory signalProof = ISignalService.SignalProof(accountProof, storageProof);
        anchor.anchor(1, 0x96f93471972581d5ece97604948e4013972fadb5e47514b1f11f1da85c68d476);
        L2signalService.verifySignal(1, 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, signal, abi.encode(signalProof));
    }
}
