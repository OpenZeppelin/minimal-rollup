// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibValueTicket} from "../libs/LibValueTicket.sol";

/// @dev Bridges native value (i.e. ETH) by creating and verifying tickets using the `LibValueTicket`.
///
/// These can be created by sending value to the `createTicket` function. Later, the receiver can claim the ticket on
/// the destination chain by using a storage proof.
///
/// ETH bridge MUST be deployed at the same address on both chains.
interface IETHBridge {
    /// @dev Sender (`from`) sent `value` at `blockNumber` to the receiver (`to`). Claimable on `chainId`.
    event ETHTicket(LibValueTicket.ValueTicket ticket);

    /// @dev Failed to call the receiver with value.
    error FailedClaim();

    /// @dev Ticket was already claimed.
    error AlreadyClaimed();

    /// @dev Whether the ticket identified by `id` has been claimed.
    function claimed(bytes32 id) external view returns (bool);

    /// @dev Ticket identifier.
    function ticketId(LibValueTicket.ValueTicket memory ticket) external view returns (bytes32 id);

    /// @dev Verifies if a ticket defined created on the `chainId` at `blockNumber` by the receiver (`from`) is valid
    /// for the receiver `to` to claim `value` on this chain by performing an storage proof of this bridge address using
    /// `accountProof` and validating it against the network state root using `proof`.
    function verifyTicket(
        LibValueTicket.ValueTicket memory ticket,
        bytes32 root,
        bytes[] memory accountProof,
        bytes[] memory proof
    ) external view returns (bool verified, bytes32 id);

    /// @dev Creates a ticket with `msg.value` ETH for the receiver (`to`) to claim on the `chainId`.
    function createTicket(uint64 chainId, address to) external payable;

    /// @dev Claims a ticket created on `chainId` by the sender (`from`) at `blockNumber`. The `value` ETH claimed  is
    /// sent to the receiver (`to`) after verifying the proofs. See `verifyTicket`.
    function claimTicket(
        LibValueTicket.ValueTicket memory ticket,
        bytes32 root,
        bytes[] memory accountProof,
        bytes[] memory proof
    ) external;
}
