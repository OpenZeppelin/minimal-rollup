// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IMessageRelayer} from "src/protocol/IMessageRelayer.sol";

interface IGenericRecipient {
    function setSuccess(bool _callWillSucceed) external;
    function setReentrancyAttack(bool _shouldAttack) external;
}

contract GenericRecipient is IGenericRecipient {
    bool private callWillSucceed = true;
    bool private shouldReenterAttack = false;
    address private relayer;

    // Consume a minimum amount of gas so we can test gas limits
    uint256 public constant GAS_REQUIRED = 20_000;

    error CallFailed();

    event FunctionCalled();

    constructor(address _relayer) {
        relayer = _relayer;
    }

    function setSuccess(bool _callWillSucceed) external {
        callWillSucceed = _callWillSucceed;
    }

    function setReentrancyAttack(bool _shouldAttack) external {
        shouldReenterAttack = _shouldAttack;
    }

    fallback() external payable {
        _simulateFunctionCall();
    }

    receive() external payable {
        _simulateFunctionCall();
    }

    function _simulateFunctionCall() internal {
        require(callWillSucceed, CallFailed());
        require(gasleft() >= GAS_REQUIRED, "Insufficient gas");

        emit FunctionCalled();

        if (shouldReenterAttack) {
            IMessageRelayer(relayer).receiveMessage(address(this), 0, address(this), 0, "0x");
        }
    }
}
