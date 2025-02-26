// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @dev Bridges native value (i.e. ETH) by emitting tickets.
///
/// Tickets are unique per chain (source and destination), block number, sender, receiver and value. These can be
/// created by sending value to the `createTicket` function. Later, the receiver can claim the ticket on the destination
/// chain by using a storage proof.
///
/// ETH bridge MUST be deployed at the same address on both chains.
interface IETHBridge {
    /// @dev Sender (`from`) sent `value` at `blockNumber` to the receiver (`to`). Claimable on `destinationChainId`.
    event Ticket(uint64 destinationChainId, uint64 blockNumber, address from, address to, uint256 value);

    /// @dev The ticket is not valid (i.e. couldn't be verified)
    error InvalidTicket();

    /// @dev Failed to call the receiver with value.
    error FailedClaim();

    /// @dev Ticket was already claimed.
    error AlreadyClaimed();

    /// @dev Whether the ticket identified by `id` has been claimed.
    function claimed(bytes32 id) external view returns (bool);

    /// @dev Ticket identifier.
    function ticketId(uint64 destinationChainId, uint64 blockNumber, address from, address to, uint256 value)
        external
        view
        returns (bytes32 id);

    /// @dev Verifies if a ticket defined created on the `sourceChainId` at `blockNumber` by the receiver (`from`) is
    /// valid for the receiver `to` to claim `value` on this chain by performing an storage proof of this bridge address
    /// using `accountProof` and validating it against the network state root using `proof`.
    function verifyTicket(
        uint64 sourceChainId,
        uint64 blockNumber,
        address from,
        address to,
        uint256 value,
        bytes32 root,
        bytes[] calldata accountProof,
        bytes[] calldata proof
    ) external view returns (bool verified, bytes32 id);

    /// @dev Creates a ticket with `msg.value` ETH for the receiver (`to`) to claim on the `destinationChainId`.
    function createTicket(uint64 destinationChainId, address to) external payable;

    /// @dev Claims a ticket created on `sourceChainId` by the sender (`from`) at `blockNumber`. The `value` ETH claimed
    /// is sent to the receiver (`to`) after verifying the proofs. See `verifyTicket`.
    function claimTicket(
        uint64 sourceChainId,
        uint64 blockNumber,
        address from,
        address to,
        uint256 value,
        bytes32 root,
        bytes[] calldata accountProof,
        bytes[] calldata proof
    ) external;
}
