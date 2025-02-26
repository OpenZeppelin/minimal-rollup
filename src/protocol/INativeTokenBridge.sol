// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface INativeBridge {
    event Transfer(uint64 blockNumber, address from, address to, uint256 value);

    error InvalidClaim();

    function transferId(uint64 chainId, uint64 blockNumber, address from, address to, uint256 value)
        external
        view
        returns (bytes32 id);

    function verifyClaim(
        uint64 sourceChainId,
        uint64 blockNumber,
        address from,
        address to,
        uint256 value,
        bytes32 root,
        bytes[] calldata proof
    ) external view returns (bool verified, bytes32 id);

    function transfer(address to) external payable;

    function claim(
        uint64 sourceChainId,
        uint64 blockNumber,
        address from,
        address to,
        uint256 value,
        bytes32 root,
        bytes[] calldata proof
    ) external;
}
