// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {ETHBridge} from "src/protocol/ETHBridge.sol";

import {MessageRelayer} from "src/protocol/taiko_alethia/MessageRelayer.sol";
import {MockSignalService} from "test/mocks/MockSignalService.sol";

abstract contract InitialState is Test {
    MessageRelayer messageRelayer;

    function setUp() public virtual {
        MockSignalService signalService = new MockSignalService();
        address trustedCommitmentPublisher = _randomAddress("trustedCommitmentPublisher");
        address counterpart = _randomAddress("counterpart");
        ETHBridge bridge = new ETHBridge(address(signalService), trustedCommitmentPublisher, counterpart);
        messageRelayer = new MessageRelayer(address(bridge));
    }

    function _randomAddress(string memory name) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encode(_domainSeparator(), name)))));
    }

    function _domainSeparator() internal pure returns (bytes32) {
        return keccak256("MessageRelayer");
    }
}
