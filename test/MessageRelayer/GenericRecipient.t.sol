// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract GenericRecipient {
    bool private callWillSucceed = true;

    error CallFailed();

    event FunctionCalled();

    function setSuccess(bool _callWillSucceed) external {
        callWillSucceed = _callWillSucceed;
    }

    fallback() external payable {
        _simulateFunctionCall();
    }

    receive() external payable {
        _simulateFunctionCall();
    }

    function _simulateFunctionCall() internal {
        require(callWillSucceed, CallFailed());
        emit FunctionCalled();
    }
}
