// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../src/blobs/IBlobRefRegistry.sol";
import {Test} from "forge-std/Test.sol";

contract MockBlobRefRegistry is Test {
    function getRef(uint256[] calldata blobIndices) external view returns (IBlobRefRegistry.BlobRef memory) {
        uint256 nBlobs = blobIndices.length;

        bytes32[] memory blobhashes = new bytes32[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            // simulate a blobhash
            blobhashes[i] = keccak256(abi.encode(vm.randomUint(256)));
        }
        return IBlobRefRegistry.BlobRef(block.number, blobhashes);
    }
}
