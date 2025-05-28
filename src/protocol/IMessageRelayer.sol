// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IETHBridge} from "./IETHBridge.sol";

interface IMessageRelayer {
    /// @dev Emitted when a message has been successfully forwarded.
    /// @param to Address forwarded to
    /// @param amount Amount forwarded
    /// @param data Data forwarded
    /// @param tipRecipient Address that received the tip
    /// @param tip Tip received
    event MessageForwarded(address indexed to, uint256 amount, bytes data, address tipRecipient, uint256 tip);

    /// @dev Relayer did not provide a high enough gas amount
    error InsufficientGas();

    /// @dev Message forwarding failed
    error MessageForwardingFailed();

    /// @dev Tip transfer failed
    error TipSendingFailed();

    /// @notice Executes the claimDeposit function on the ETHBridge.
    /// @dev Implements any intermediary step to claim the deposit (i.e. stores tipRecipient address)
    /// @param ethDeposit The deposit to claim
    /// @param height The `height` of the checkpoint on the source chain (i.e. the block number or publicationId)
    /// @param proof Proof of the deposit
    /// @param tipRecipient Address the relayer will send the tip to (chosen by the relayer)
    function relayMessage(
        IETHBridge.ETHDeposit memory ethDeposit,
        uint256 height,
        bytes memory proof,
        address tipRecipient
    ) external;

    /// @notice Receives a message from the bridge.
    /// @dev Handles logic for receiving a message from the bridge (i.e. sending fees and forwarding the message if
    /// needed).
    /// @param to Address to send the ETH to
    /// @param tip Tip to send to the tip recipient
    /// @param gasLimit Gas limit to use when forwarding the message
    /// @param data Data to send to the recipient
    function receiveMessage(address to, uint256 tip, uint256 gasLimit, bytes memory data) external payable;
}
