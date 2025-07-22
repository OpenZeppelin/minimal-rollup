// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {ETHBridge} from "src/protocol/ETHBridge.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

import {MessageRecipient} from "./MessageRecipient.t.sol";
import {IMessageRelayer} from "src/protocol/IMessageRelayer.sol";
import {MessageRelayer} from "src/protocol/taiko_alethia/MessageRelayer.sol";
import {MockSignalService} from "test/mocks/MockSignalService.sol";

abstract contract InitialState is Test {
    MessageRelayer messageRelayer;

    // Default message parameters
    IETHBridge.ETHDeposit ethDeposit;
    uint256 height = 0;
    bytes proof = "0x";
    MessageRecipient to;
    uint256 amount = 2 ether;
    uint256 tip = 0.1 ether;
    address relayerSelectedTipRecipient = _randomAddress("relayerSelectedTipRecipient");
    address userSelectedTipRecipient = _randomAddress("userSelectedTipRecipient");
    uint256 gasLimit = 0;
    bytes data = "0x";

    function setUp() public virtual {
        MockSignalService signalService = new MockSignalService();
        address trustedCommitmentPublisher = _randomAddress("trustedCommitmentPublisher");
        address counterpart = _randomAddress("counterpart");
        to = new MessageRecipient();
        ETHBridge bridge = new ETHBridge(address(signalService), trustedCommitmentPublisher, counterpart);
        vm.deal(address(bridge), amount);

        messageRelayer = new MessageRelayer(address(bridge));

        ethDeposit = IETHBridge.ETHDeposit({
            nonce: 0,
            from: _randomAddress("from"),
            to: address(messageRelayer),
            amount: 2 ether,
            data: "",
            context: "",
            canceler: address(0)
        });
        _encodeReceiveCall();
    }

    function _encodeReceiveCall() internal {
        ethDeposit.data =
            abi.encodeCall(IMessageRelayer.receiveMessage, (address(to), tip, userSelectedTipRecipient, gasLimit, data));
    }

    function _randomAddress(string memory name) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encode(_domainSeparator(), name)))));
    }

    function _domainSeparator() internal pure returns (bytes32) {
        return keccak256("MessageRelayer");
    }
}
