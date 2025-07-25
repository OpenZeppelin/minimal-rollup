// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ISignalService} from "src/protocol/ISignalService.sol";

contract MockSignalService is ISignalService {
    error NotImplemented();

    function sendSignal(bytes32) external pure returns (bytes32) {
        revert NotImplemented();
    }

    function isSignalStored(bytes32, address) external pure returns (bool) {
        revert NotImplemented();
    }

    // verification always succeeds
    function verifySignal(
        uint256, /* height */
        address, /* commitmentPublisher */
        address, /* sender */
        bytes32, /* value */
        bytes memory /* proof */
    ) external view {}
}
