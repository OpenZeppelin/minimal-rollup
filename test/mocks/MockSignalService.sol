// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ISignalService} from "src/protocol/ISignalService.sol";

contract MockSignalService is ISignalService {
    bool verifyResult;

    function setVerifyResult(bool _result) external {
        verifyResult = _result;
    }

    function verifySignal(uint256 _height, address _publisher, address _sender, bytes32 _signal, bytes memory _proof)
        external
        view
    {
        require(verifyResult, "Mock verify failed");
    }

    function sendSignal(bytes32 _signal) external pure returns (bytes32 slot) {
        slot = keccak256(abi.encodePacked(_signal));
    }

    function isSignalStored(bytes32 _signal, address _sender) external pure returns (bool) {
        return true;
    }
}
