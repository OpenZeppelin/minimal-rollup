// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {IDelayedInclusionStore} from "src/protocol/IDelayedInclusionStore.sol";
import {DelayedInclusionStore} from "src/protocol/taiko_alethia/DelayedInclusionStore.sol";
import {MockBlobRefRegistry} from "test/mocks/MockBlobRefRegistry.sol";

contract DelayedInclusionStoreTest is Test {
    using stdStorage for StdStorage;

    DelayedInclusionStore inclusionStore;
    MockBlobRefRegistry blobReg;
    // Addresses used for testing.
    address inbox = address(0x100);

    uint256 public inclusionDelay = 10 minutes;
    uint256 public constant waitTime = 2 hours;

    function setUp() public {
        blobReg = new MockBlobRefRegistry();
        inclusionStore = new DelayedInclusionStore(inclusionDelay, address(blobReg), inbox);
        storeDelayedInclusions(25);
        vm.warp(waitTime);
        storeDelayedInclusions(25);
        vm.warp(1);
    }

    function storeDelayedInclusions(uint256 numInclusions) public {
        for (uint256 i; i < numInclusions; ++i) {
            uint256[] memory blobIndices = new uint256[](1);
            blobIndices[0] = i;
            inclusionStore.publishDelayed(blobIndices);
        }
    }

    function readInclusionArray(uint256 index) public view returns (DelayedInclusionStore.DueInclusion memory) {
        uint256 slot = 0;
        uint256 baseSlot = uint256(keccak256(abi.encode(slot))) + (index * 2);
        bytes32 blobRefHash = vm.load(address(inclusionStore), bytes32(baseSlot));
        uint256 due = uint256(vm.load(address(inclusionStore), bytes32(baseSlot + 1)));

        return DelayedInclusionStore.DueInclusion(blobRefHash, due);
    }

    function test_processDueInclusions_NoneDue() public {
        vm.prank(inbox);
        DelayedInclusionStore.Inclusion[] memory inclusions = inclusionStore.processDueInclusions();
        assertEq(inclusions.length, 0);
    }

    function test_processDueInclusions_FirstHalfDue() public {
        vm.prank(inbox);
        vm.warp(inclusionDelay + 1);
        DelayedInclusionStore.Inclusion[] memory inclusions = inclusionStore.processDueInclusions();
        assertEq(inclusions.length, 25);
        assertEq(inclusions[0].blobRefHash, readInclusionArray(0).blobRefHash);
        assertEq(inclusions[24].blobRefHash, readInclusionArray(24).blobRefHash);
    }

    function test_processDueInclusions_SecondHalfDue() public {
        vm.startPrank(inbox);
        vm.warp(inclusionDelay + 1);
        inclusionStore.processDueInclusions();
        vm.warp(waitTime + inclusionDelay + 1);
        DelayedInclusionStore.Inclusion[] memory inclusions = inclusionStore.processDueInclusions();
        assertEq(inclusions.length, 25);
        assertEq(inclusions[0].blobRefHash, readInclusionArray(25).blobRefHash);
        assertEq(inclusions[24].blobRefHash, readInclusionArray(49).blobRefHash);
        vm.stopPrank();
    }

    function test_processDueInclusions_AllDue() public {
        vm.prank(inbox);
        vm.warp(waitTime + inclusionDelay + 1);
        DelayedInclusionStore.Inclusion[] memory inclusions = inclusionStore.processDueInclusions();
        assertEq(inclusions.length, 50);
        assertEq(inclusions[0].blobRefHash, readInclusionArray(0).blobRefHash);
        assertEq(inclusions[49].blobRefHash, readInclusionArray(49).blobRefHash);
    }

    function test_processDueInclusions_RevertWhen_NotInbox() public {
        vm.warp(inclusionDelay + 1);
        vm.expectRevert("Only inbox can process inclusions");
        inclusionStore.processDueInclusions();
    }
}
