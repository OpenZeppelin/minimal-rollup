// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {ETHBridge} from "src/protocol/ETHBridge.sol";
import {SignalService} from "src/protocol/SignalService.sol";

contract InitialState is Test {
    ETHBridge bridge;
    SignalService signalService;

    address trustedCommitmentPublisher = _randomAddress("trustedCommitmentPublisher");
    address counterpart = _randomAddress("counterpart");

    function setUp() public virtual {
        signalService = new SignalService();
        bridge = new ETHBridge(address(signalService), trustedCommitmentPublisher, counterpart);
    }

    function _randomAddress(string memory name) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encode(_domainSeparator(), name)))));
    }

    function _domainSeparator() internal pure returns (bytes32) {
        return keccak256("ETHBridge");
    }

    function getNonce() internal view returns (uint256) {
        return uint256(vm.load(address(bridge), bytes32(uint256(1))));
    }
}
