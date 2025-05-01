// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IETHBridge} from "./IETHBridge.sol";

interface IMessageRelayer {
    /// @dev Executes the claimDeposit function on the ETHBridge.
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

    /// @dev Handles logic for receiving a message from the bridge (i.e. sending fees and forwarding the message if
    /// needed).
    /// @param to Address to send the ETH to
    /// @param fee Fee to send to the relayer
    /// @param data Data to send to the receiver
    function receiveMessage(address to, uint256 fee, bytes memory data) external payable;
}
