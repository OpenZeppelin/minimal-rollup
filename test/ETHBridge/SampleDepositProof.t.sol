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
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0acd0d5394c74002c8044fcc5e18b86c12eac7f28d7bd928dd23020f3080729a8a0f6302dc31ed7de56838cd0748cf8532cf336115b1b4b88ad75b581f79e1efef780a079b78e3e8d6565d6faf94f09a3e79c05da3f4663255a38aecdfd17b6bf25a5dda04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a008d5acaefa3f89fc421a25cc9ef2906ecb72ab7a9201626ce5e161e6c514dbe8a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a05e10cbcc81a653991ad6f5acfba8b30facc943d4d77a1e9461361de59665e85e80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0f16ae9cbd9fa7f4a1259e5debc440d5e779e7edef20ac93ec3d095feb7336dcda0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f85180a02863e30453fc835f21fc770459600a7777e29b915a1abe217cb3ea8b6571a8bb8080808080808080a0e1f9589d66b85cc75e2da357788433afcc24be5e18551f33aeb690e2c2a089be808080808080";
        storageProof[1] = hex"e2a034fae02acd15bbf46ecee8fa4a72c97d17c1e2e719ac7517b63a1c1cde135a1801";
        deposit.nonce = 0;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xc0861da4adda5f350f55acc981f72fcac9ffc3c97d3b55c7525f254986065300),
            bytes32(0x103b147e6dacf071f9fe23d0088a650be67e2412f334115cbc3fa20404b360fd)
        );

        // Populate proof 1
        accountProof = new bytes[](3);
        accountProof[0] =
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a0acd0d5394c74002c8044fcc5e18b86c12eac7f28d7bd928dd23020f3080729a8a0f6302dc31ed7de56838cd0748cf8532cf336115b1b4b88ad75b581f79e1efef780a079b78e3e8d6565d6faf94f09a3e79c05da3f4663255a38aecdfd17b6bf25a5dda04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a008d5acaefa3f89fc421a25cc9ef2906ecb72ab7a9201626ce5e161e6c514dbe8a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a05e10cbcc81a653991ad6f5acfba8b30facc943d4d77a1e9461361de59665e85e80808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a0f16ae9cbd9fa7f4a1259e5debc440d5e779e7edef20ac93ec3d095feb7336dcda0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";
        storageProof = new bytes[](2);
        storageProof[0] =
            hex"f85180a02863e30453fc835f21fc770459600a7777e29b915a1abe217cb3ea8b6571a8bb8080808080808080a0e1f9589d66b85cc75e2da357788433afcc24be5e18551f33aeb690e2c2a089be808080808080";
        storageProof[1] = hex"e2a032244b550e204d9cb9a298654700fb6f593e6fc27070d907ee4ecec30419e36b01";
        deposit.nonce = 1;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes(hex"7062c09400000000000000000000000000000000000000000000000000000000000004d2");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xded19bc26e131c40d7db15c07113941e6c65e1e5bcad6c5e248b2377abc92800),
            bytes32(0x3ef6eb196677946bf990bfd6811b4a5bdfe50df175ea661f8ba144982c2d246d)
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
        return bytes32(0xbd1e9eed45836a4e1da012c340e46206fc746b51d0cf10a1d6ac17b68e337411);
    }

    /// @inheritdoc ISampleDepositProof
    function getBlockHash() public pure returns (bytes32) {
        return bytes32(0xdc4edf948d3550d8ad7aad965c56ddfa121a9ac2b276511405430d6f060b9dde);
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
