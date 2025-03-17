// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {StdStorage, stdStorage} from "forge-std/Test.sol";

import {IDelayedInclusionStore} from "src/protocol/IDelayedInclusionStore.sol";
import {DelayedInclusionStore} from "src/protocol/taiko_alethia/DelayedInclusionStore.sol";
import {MockBlobRefRegistry} from "test/mocks/MockBlobRefRegistry.sol";

contract DelayedInclusionStoreTest is Test {
    using stdStorage for StdStorage;

    DelayedInclusionStore store;
    MockBlobRefRegistry blobReg;
    // Addresses used for testing.
    address inbox = address(0x100);

    uint256 public inclusionDelay = 10 minutes;

    function setUp() public {
        blobReg = new MockBlobRefRegistry();
        store = new DelayedInclusionStore(inclusionDelay, address(blobReg), inbox);
        storeDelayedInclusions(25);
        vm.warp(2 hours);
        storeDelayedInclusions(25);
        vm.warp(1);
    }

    function storeDelayedInclusions(uint256 numInclusions) public {
        for (uint256 i; i < numInclusions; ++i) {
            uint256[] memory blobIndices = new uint256[](1);
            blobIndices[0] = i;
            store.publishDelayed(blobIndices);
        }
    }

    function test_processHalfDueInclusions() public {
        vm.prank(inbox);
        vm.warp(inclusionDelay + 1);
        uint256 returnLen = store.processDueInclusions().length;
        assertEq(returnLen, 25);
    }

    function test_processAllDueInclusions() public {
        vm.prank(inbox);
        vm.warp(inclusionDelay + 2 hours + 1);
        store.processDueInclusions();
        uint256 returnLen = store.processDueInclusions().length;
        assertEq(returnLen, 50);
    }

    function test_processDueInclusions_noInclusions() public {
        vm.prank(inbox);
        uint256 returnLen = store.processDueInclusions().length;
        assertEq(returnLen, 0);
    }
}
