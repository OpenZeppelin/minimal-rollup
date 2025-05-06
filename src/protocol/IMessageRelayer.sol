// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IETHBridge} from "./IETHBridge.sol";

interface IMessageRelayer {
    /// @dev Emitted when a deposit has been successfully claimed.
    /// @param ethDeposit Deposit claimed
    /// @param relayer Address of the relayer that claimed the deposit
    event RelayInitiated(IETHBridge.ETHDeposit indexed ethDeposit, address relayer);

    /// @dev Emitted when a message has been successfully forwarded.
    /// @param to Address forwarded to
    /// @param amount Amount forwarded
    /// @param data Data forwarded
    event MessageForwarded(address indexed to, uint256 amount, bytes data);

    /// @dev User did not provide a high enough gas limit
    error InsufficientGasLimit();

    /// @dev Message forwarding failed
    error MessageForwardingFailed();

    /// @notice Executes the claimDeposit function on the ETHBridge.
    /// @dev Implements any intermediary step to claim the deposit (i.e. stores relayer address)
    /// @param ethDeposit Deposit to claim
    /// @param height Height of the L2 block
    /// @param proof Proof of the deposit
    /// @param relayerAddress Address of the relayer to send fee to
    function relayMessage(
        IETHBridge.ETHDeposit memory ethDeposit,
        uint256 height,
        bytes memory proof,
        address relayerAddress
    ) external;

    /// @notice Receives a message from the bridge.
    /// @dev Handles logic for receiving a message from the bridge (i.e. sending fees and forwarding the message if
    /// needed).
    /// @param to Address to send the ETH to
    /// @param fee Fee to send to the relayer
    /// @param gasLimit Gas limit to use when forwarding the message
    /// @param data Data to send to the receiver
    function receiveMessage(address to, uint256 fee, uint256 gasLimit, bytes memory data) external payable;
}
