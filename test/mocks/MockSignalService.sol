// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ISignalService} from "src/protocol/ISignalService.sol";

contract MockSignalService is ISignalService {
    bool verifyResult;

    function setVerifyResult(bool _result) external {
        verifyResult = _result;
    }

    function verifySignal(uint256 height, address publisher, address sender, bytes32 signal, bytes memory proof) external view {
        require(verifyResult, "Mock verify failed");
    }

    function sendSignal(bytes32 signal) external returns (bytes32 slot) {
        slot = keccak256(abi.encodePacked(signal));
    }

    function isSignalStored(bytes32 signal, address sender) external view returns (bool) {
        return true;
    }
} 