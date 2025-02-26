// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICommitmentSyncer {
    event CommitmentSynced(uint64 indexed chainId, uint64 indexed publicationId, bytes32 commitment);

    function syncValue(uint64 chainId, uint64 publicationId, bytes32 commitment)
        external
        pure
        returns (bytes32 value);

    function commitmentAt(uint64 chainId, uint64 publicationId) external view returns (bytes32 commitment);

    function latestCommitment(uint64 chainId) external view returns (bytes32 commitment);

    function latestPublicationId(uint64 chainId) external view returns (uint64 publicationId);

    function verifyCommitment(
        uint64 chainId,
        uint64 publicationId,
        bytes32 commitment,
        bytes32 root,
        bytes[] calldata proof
    ) external view returns (bool valid);

    function syncCommitment(uint64 chainId, uint64 publicationId, bytes32 commitment) external;
}
