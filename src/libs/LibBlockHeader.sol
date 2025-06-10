// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library LibBlockHeader {
    /// @dev This contains all the fields of the Ethereum block header in the cancun fork taken from
    /// https://github.com/ethereum/go-ethereum/blob/master/core/types/block.go#L75
    struct BlockHeader {
        bytes32 parentHash;
        bytes32 omnersHash;
        address coinbase;
        bytes32 stateRoot;
        bytes32 transactionsRoot;
        bytes32 receiptsRoot;
        bytes logsBloom;
        uint256 difficulty;
        uint256 number;
        uint64 gasLimit;
        uint64 gasUsed;
        uint64 timestamp;
        bytes extraData;
        bytes32 mixedHash;
        uint64 nonce;
        bytes32 baseFeePerGas;
        bytes32 withdrawalsRoot;
        uint64 blobGasUsed;
        uint64 excessBlobGas;
        bytes32 parentBeaconBlockRoot;
        bytes32 requestsHash;
    }

    // Domain separators to identify individual fields
    bytes32 constant BLOCK_HASH = keccak256("BlockHeaderHash");
    bytes32 constant PARENT_HASH = keccak256("BlockHeaderParentHash");
    bytes32 constant STATE_ROOT = keccak256("BlockHeaderStateRoot");
}
