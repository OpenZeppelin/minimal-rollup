// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ISignalService} from "../ISignalService.sol";

interface IStateSyncer {
    event ChainDataSynced(uint64 indexed chainId, uint64 indexed blockNumber, bytes32 root);

    function syncSignal(uint64 chainId, uint64 blockNumber, bytes32 root) external view returns (bytes32 signal);

    function stateAt(uint64 chainId, uint64 blockNumber) external view returns (bytes32 root);

    function latestState(uint64 chainId) external view returns (bytes32 root);

    function latestBlock(uint64 chainId) external view returns (uint64 blockNumber);

    function verifyState(uint64 chainId, uint64 blockNumber, bytes32 root, bytes[] calldata proof)
        external
        view
        returns (bool valid);

    function syncState(uint64 chainId, uint64 blockNumber, bytes32 root) external;
}
