// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../src/blobs/IBlobRefRegistry.sol";

contract MockBlobRefRegistry is IBlobRefRegistry {
    mapping(bytes32 refHash => uint256 timestamp) private _registeredHashes;

    function registerRef(uint256[] calldata blobIndices) external returns (bytes32 refHash, BlobRef memory ref) {
        ref = _getRef(blobIndices);
        refHash = _registerRefHash(ref);
        emit Registered(refHash, ref);
    }

    function getRef(uint256[] calldata blobIndices) external view returns (BlobRef memory) {
        return _getRef(blobIndices);
    }

    function isRefRegistered(bytes32 refHash) external view returns (bool) {
        return _registeredHashes[refHash] != 0;
    }

    function _registerRefHash(BlobRef memory ref) private returns (bytes32) {
        bytes32 hash = keccak256(abi.encode(ref));
        _registeredHashes[hash] = block.timestamp;
        emit Registered(hash, ref);
        return hash;
    }

    function _getRef(uint256[] calldata blobIndices) private view returns (BlobRef memory) {
        uint256 nBlobs = blobIndices.length;

        bytes32[] memory blobhashes = new bytes32[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobhashes[i] = blobhash(blobIndices[i]);
        }
        return BlobRef(block.number, blobhashes);
    }
}
