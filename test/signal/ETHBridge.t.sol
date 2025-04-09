// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {BaseState} from "./SignalService.t.sol";

import {ETHBridge} from "src/protocol/ETHBridge.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

// represents state where a deposit is made on L1
// however, the it is not yet available on L2
contract BridgeETHState is BaseState {
    bytes32 public depositIdOne;
    uint256 public depositAmount = 4 ether;

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(L1Fork);

        vm.prank(defaultSender);
        bytes memory emptyData = "";
        depositIdOne = L1signalService.deposit{value: depositAmount}(defaultSender, emptyData);
    }
}

contract ETHBridgeTest is BridgeETHState {
    function test_initialDepositState() public {
        assertEq(address(L1signalService).balance, ETHBridgeInitBalance + depositAmount);
        assertEq(defaultSender.balance, senderBalanceL1 - depositAmount);

        vm.selectFork(L2Fork);
        assertEq(L2signalService.claimed(depositIdOne), false);
        assertEq(defaultSender.balance, senderBalanceL2);
    }
}

contract CommitmentStoredState is BridgeETHState {
    bytes32 public stateRoot = hex"224e99b0de9ed68375f3458bd781b9f005a513896926ab40efcefa53b206e676";
    bytes32 public storageRoot = hex"c68ba023e3d1f98a6dd54da471f7083a3c5688c2155e025aa6057bb4b12d4a7f";
    uint256 public commimentHeight = 1;

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(L2Fork);
        anchor.anchor(commimentHeight, stateRoot);
    }

    // NOTE: This proof is only valid for the defaultSender address and depositIDOne
    // For the given stateRoot and storageRoot
    function storageProofDepositOne() public pure returns (bytes[] memory storageProofArr) {
        storageProofArr = new bytes[](3);
        storageProofArr[0] = hex"e214a02e2494ebc8fb952234c6ddb26272b62902092620f9f43875410a26ab3b5780fc";
        storageProofArr[1] =
            hex"f851a0ad42e1edb0c73638954137aa6a8b81f68c8bb79b345826de7aa15c82de29bee08080808080808080808080808080a01b57f4f95939ad40e32a28c25dcae27ffe80117c2d69884160afa44350fb0e9580";
        storageProofArr[2] =
            hex"f843a02029ed229bb9f7c4f29d2ec510e2d8da153589bcda88f5554c41b350706c5419a1a0f9c183d2de58fbeb1a8917170139e980fa1b6e5a358ec83721e11c9f6e25eb18";
    }

    // NOTE: This proof is only valid for the defaultSender address and depositIDOne
    // For the given stateRoot and storageRoot
    function accountProofDepositOne() public pure returns (bytes[] memory accountProofArr) {
        accountProofArr = new bytes[](3);
        accountProofArr[0] =
            hex"f90131a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0995ee372e18bdf6426d3b5bd991f3fbd484089e5ae83624c4b0f135130642414a06c2269d1607a5bef075823f983118537ceb14a5d86d863a621713a49f3da953c8080a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a0963ad7d87647a7be721f455038bb809851cea3d2d3f518dc6f1361f9bc403256a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProofArr[1] =
            hex"f85180808080a00d86b4b457dc153ccc8440169928f6b0bfbfa83b9ade80c69644cdb6b7bf8e8580808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProofArr[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0c68ba023e3d1f98a6dd54da471f7083a3c5688c2155e025aa6057bb4b12d4a7fa0d3b8e729dd4ca4de578010915680ec30df020b6c77a2b9e3feadde451c82fc0f";
    }
}

contract ClaimDepositTest is CommitmentStoredState {
    function test_claimDeposit() public {
        vm.selectFork(L2Fork);

        bytes[] memory accountProof = accountProofDepositOne();
        bytes[] memory storageProof = storageProofDepositOne();
        ISignalService.SignalProof memory signalProof = ISignalService.SignalProof(accountProof, storageProof);
        bytes memory encodedProof = abi.encode(signalProof);

        ETHBridge.ETHDeposit memory ethDeposit;
        ethDeposit.nonce = 0;
        ethDeposit.from = defaultSender;
        ethDeposit.to = defaultSender;
        ethDeposit.amount = depositAmount;
        ethDeposit.data = "";

        L2signalService.claimDeposit(ethDeposit, commimentHeight, encodedProof);

        assertEq(address(L2signalService).balance, ETHBridgeInitBalance - depositAmount);
        assertEq(defaultSender.balance, senderBalanceL2 + depositAmount);
    }
}
