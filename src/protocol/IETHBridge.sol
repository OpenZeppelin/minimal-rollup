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
    event Ticket(uint64 destinationChainId, uint64 blockNumber, address from, address to, uint256 value);

    error InvalidTicket();
    error FailedClaim();
    error AlreadyClaimed();

    function claimed(bytes32 id) external view returns (bool);

    function ticketId(uint64 destinationChainId, uint64 blockNumber, address from, address to, uint256 value)
        external
        view
        returns (bytes32 id);

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

    function createTicket(uint64 destinationChainId, address to) external payable;

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
