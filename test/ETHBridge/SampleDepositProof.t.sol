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
            hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a003c2f506dcc4351bbb1f7943084665e21af2cad3f37618a794167901174fc2caa07b9b5af76aaacfe822062ed002c6db0b494ae66b9dbe3e91c7c398088a92090480a0931c5d4ef4b2277973028722fd557c9eb65b9db5f7788c27005ce5ae5c677a86a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a046e3a6bd785b2f60ecc9f58b5302daf708d8328307670dba4b5226236db6f148a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
        accountProof[1] =
            hex"f85180808080a01de1625cbf687e609d7804db12584ef214fabb3b641724a737b2f3fc8496957480808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
        accountProof[2] =
            hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a095aad4770cd67977ac25c687f94d3ccaaeb0ae1bf39482feba4717bc2b1b888fa0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";
        storageProof = new bytes[](1);
        storageProof[0] = hex"e3a120a4fae02acd15bbf46ecee8fa4a72c97d17c1e2e719ac7517b63a1c1cde135a1801";
        deposit.nonce = 0;
        deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
        deposit.amount = 4000000000000000000;
        deposit.data = bytes("");
        _createDeposit(
            accountProof,
            storageProof,
            deposit,
            bytes32(0xc0861da4adda5f350f55acc981f72fcac9ffc3c97d3b55c7525f254986065300),
            bytes32(0x103b147e6dacf071f9fe23d0088a650be67e2412f334115cbc3fa20404b360fd)
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
        return bytes32(0xb7711f031190aae5617914df7c3d4d2d2496031986f5b8dcd6ac7d8daeef424b);
    }

    /// @inheritdoc ISampleDepositProof
    function getBlockHash() public pure returns (bytes32) {
        return bytes32(0x79c4a5b6b93a85f4528227f6a9f069d42c7d616a1d0c050dd5300f014914cd8d);
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

    /// @inheritdoc ISampleDepositProof
    function getNumberOfProofs() public view returns (uint256 count) {
        count = signalProofs.length;
        require(deposits.length == count, "Deposit count mismatch");
        require(slots.length == count, "Slot count mismatch");
        require(ids.length == count, "ID count mismatch");
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
}
