// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "src/libs/LibSignal.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

contract MockSignalService is ISignalService {
    bool verifyResult;
    bytes32 public lastSignalId;

    using LibSignal for bytes32;

    function setVerifyResult(bool _result) external {
        verifyResult = _result;
    }

    function verifySignal(uint256 _height, address _publisher, address _sender, bytes32 _signal, bytes memory _proof)
        external
        view
    {
        require(verifyResult, "Mock verify failed");
    }

    function sendSignal(bytes32 _signal) external returns (bytes32 slot) {
        lastSignalId = _signal;
        _signal.signal();
    }

    function isSignalStored(bytes32 _signal, address _sender) external view returns (bool) {
        return _signal.signaled(_sender);
    }
}
