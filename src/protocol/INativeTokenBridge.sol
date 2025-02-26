// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface INativeTokenBridge {
    event Ticket(uint64 blockNumber, address from, address to, uint256 value);

    error InvalidTicket();
    error FailedClaim();

    function claimed(bytes32 id) external view returns (bool);

    function ticketId(uint64 chainId, uint64 blockNumber, address from, address to, uint256 value)
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
        bytes[] calldata proof
    ) external view returns (bool verified, bytes32 id);

    function createTicket(address to) external payable;

    function claimTicket(
        uint64 sourceChainId,
        uint64 blockNumber,
        address from,
        address to,
        uint256 value,
        bytes32 root,
        bytes[] calldata proof
    ) external;
}
