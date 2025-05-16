// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// This file is auto-generated with the command `just get-sample-deposit-proof`.
// Do not edit manually.
// See ISampleDepositProof.t.sol for an explanation of its purpose.

import {ISignalService} from "src/protocol/ISignalService.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {ISampleDepositProof} from "./ISampleDepositProof.t.sol";

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
		accountProof[0] = hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a071df4fe3124f5aeba5f4ce5916b1ddad942f45114f836f5d12c4b1eda10b076ea0a583b799152773ea834eddac071d94013064b98558ac97ae975e33be8ba725fc80a0ea1b1cdc7adf7b6a1c77c4d1eb9989aed5e7470e487e31610198b3f1b1bc62c7a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a05a8eac35436529b043308b14637b8cea95b7240457a591dcc4c6972b6e539e33a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
		accountProof[1] = hex"f85180808080a05a0705b5f53a036ff277bc41c6f6959e2ae34b0ff760a5f2a90b56f046bfc6c180808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
		accountProof[2] = hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a08ef2f5c935d88c46b15fb2c796a3ca870036fe3405c9d5c351bea25c972d2efaa0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";
		storageProof = new bytes[](2);
		storageProof[0] = hex"f87180a02863e30453fc835f21fc770459600a7777e29b915a1abe217cb3ea8b6571a8bb8080808080808080a0e1f9589d66b85cc75e2da357788433afcc24be5e18551f33aeb690e2c2a089be8080a081a79d0adf663407d9ba3b2244329d2789da644f6b618fdf10472c9c7c6b37d8808080";
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
		accountProof[0] = hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a071df4fe3124f5aeba5f4ce5916b1ddad942f45114f836f5d12c4b1eda10b076ea0a583b799152773ea834eddac071d94013064b98558ac97ae975e33be8ba725fc80a0ea1b1cdc7adf7b6a1c77c4d1eb9989aed5e7470e487e31610198b3f1b1bc62c7a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a05a8eac35436529b043308b14637b8cea95b7240457a591dcc4c6972b6e539e33a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
		accountProof[1] = hex"f85180808080a05a0705b5f53a036ff277bc41c6f6959e2ae34b0ff760a5f2a90b56f046bfc6c180808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
		accountProof[2] = hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a08ef2f5c935d88c46b15fb2c796a3ca870036fe3405c9d5c351bea25c972d2efaa0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";
		storageProof = new bytes[](2);
		storageProof[0] = hex"f87180a02863e30453fc835f21fc770459600a7777e29b915a1abe217cb3ea8b6571a8bb8080808080808080a0e1f9589d66b85cc75e2da357788433afcc24be5e18551f33aeb690e2c2a089be8080a081a79d0adf663407d9ba3b2244329d2789da644f6b618fdf10472c9c7c6b37d8808080";
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

		// Populate proof 2
		accountProof = new bytes[](3);
		accountProof[0] = hex"f90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a071df4fe3124f5aeba5f4ce5916b1ddad942f45114f836f5d12c4b1eda10b076ea0a583b799152773ea834eddac071d94013064b98558ac97ae975e33be8ba725fc80a0ea1b1cdc7adf7b6a1c77c4d1eb9989aed5e7470e487e31610198b3f1b1bc62c7a04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a05a8eac35436529b043308b14637b8cea95b7240457a591dcc4c6972b6e539e33a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680";
		accountProof[1] = hex"f85180808080a05a0705b5f53a036ff277bc41c6f6959e2ae34b0ff760a5f2a90b56f046bfc6c180808080a074ae0767a40fc6fff780050f46a50f6b39ca4edb7faa9669108157a1cd96f40980808080808080";
		accountProof[2] = hex"f869a020e659e60b21cc961f64ad47f20523c1d329d4bbda245ef3940a76dc89d0911bb846f8440180a08ef2f5c935d88c46b15fb2c796a3ca870036fe3405c9d5c351bea25c972d2efaa0da147a8683b303efc72285d333a0683c61d218e18e8dbc84e4cbf5885d4a9229";
		storageProof = new bytes[](2);
		storageProof[0] = hex"f87180a02863e30453fc835f21fc770459600a7777e29b915a1abe217cb3ea8b6571a8bb8080808080808080a0e1f9589d66b85cc75e2da357788433afcc24be5e18551f33aeb690e2c2a089be8080a081a79d0adf663407d9ba3b2244329d2789da644f6b618fdf10472c9c7c6b37d8808080";
		storageProof[1] = hex"e2a033ed1cc80b69141c895ccccd97bc3fddc6afc769831c448b544f59f03e8220b901";
		deposit.nonce = 2;
		deposit.from = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
		deposit.to = address(0x99A270Be1AA5E97633177041859aEEB9a0670fAa);
		deposit.amount = 4000000000000000000;
		deposit.data = bytes(hex"7062c09400000000000000000000000000000000000000000000000000000000000004d3");
		_createDeposit(
			accountProof,
			storageProof,
			deposit,
			bytes32(0xebc3435ae8b678186157cb65321d67651eeb3972bca9a022adc9652938208e00),
			bytes32(0x35f90af34654a8f09aca6e19f8d1bd5f7cf2221014440602a6a4f7e69d85fb5b)
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
        return bytes32(0x4f2b2bfa5fe3638d8ef365b6a386e0240ca1fa3193ffa60ac7e1efa413030141);
    }

    /// @inheritdoc ISampleDepositProof
    function getBlockHash() public pure returns (bytes32) {
        return bytes32(0xc6c0023f372bcf67b971ba1f0e01caf278b1dfbc7f34602d4ea2a66aad5258eb);
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
