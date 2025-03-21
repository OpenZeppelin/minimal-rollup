// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {IDelayedInclusionStore} from "src/protocol/IDelayedInclusionStore.sol";
import {DelayedInclusionStore} from "src/protocol/taiko_alethia/DelayedInclusionStore.sol";
import {MockBlobRefRegistry} from "test/mocks/MockBlobRefRegistry.sol";

/// State where there are no delayed inclusions.
contract BaseState is Test {
    using stdStorage for StdStorage;

    DelayedInclusionStore inclusionStore;
    MockBlobRefRegistry blobReg;
    // Addresses used for testing.
    address inbox = address(0x100);

    uint256 public inclusionDelay = 10 minutes;

    function setUp() public virtual {
        blobReg = new MockBlobRefRegistry();
        inclusionStore = new DelayedInclusionStore(inclusionDelay, address(blobReg), inbox);
    }

    function readInclusionArray(uint256 index) public view returns (DelayedInclusionStore.DueInclusion memory) {
        uint256 slot = 0;
        uint256 baseSlot = uint256(keccak256(abi.encode(slot))) + (index * 2);
        bytes32 blobRefHash = vm.load(address(inclusionStore), bytes32(baseSlot));
        uint256 due = uint256(vm.load(address(inclusionStore), bytes32(baseSlot + 1)));

        return DelayedInclusionStore.DueInclusion(blobRefHash, due);
    }
}

contract BaseStateTest is BaseState {
    function test_SetupState() public view {
        assertEq(readInclusionArray(0).blobRefHash, bytes32(0));
    }

    function test_publishDelayed_OneInclusionOneBlob() public {
        address sender = address(0x200);
        uint256[] memory blobIndices = new uint256[](1);
        // simulate a blob index
        blobIndices[0] = 1;

        bytes32 expectedRefHash = keccak256((abi.encode(blobReg.getRef(blobIndices))));
        vm.expectEmit();
        emit DelayedInclusionStore.DelayedInclusionStored(
            sender, DelayedInclusionStore.DueInclusion(expectedRefHash, vm.getBlockTimestamp() + inclusionDelay)
        );
        vm.prank(sender);
        inclusionStore.publishDelayed(blobIndices);
        assertEq(readInclusionArray(0).blobRefHash, expectedRefHash);
        assertEq(readInclusionArray(0).due, vm.getBlockTimestamp() + inclusionDelay);
    }

    function test_publish_delayed_OneInclusionMultipleBlobs() public {
        uint256[] memory blobIndices = new uint256[](2);
        // simulate blob indices
        blobIndices[0] = 1;
        blobIndices[1] = 2;

        bytes32 expectedRefHash = keccak256((abi.encode(blobReg.getRef(blobIndices))));
        inclusionStore.publishDelayed(blobIndices);
        assertEq(readInclusionArray(0).blobRefHash, expectedRefHash);
    }
}

/// State when there a multiple inclusions have been added with a staggered delay
contract StaggeredInclusionState is BaseState {
    uint256 public staggerTime = inclusionDelay + 2 hours;
    uint256 public timeA = 1000;
    uint256 public timeB = timeA + staggerTime;
    uint256 public timeC = timeB + staggerTime;
    uint256 public timeD = timeC + staggerTime;

    uint256 public constant numInclusionsA = 25;
    uint256 public constant numInclusionsB = 10;
    uint256 public constant numInclusionsC = 15;
    uint256 public constant numInclusionsD = 1;

    function setUp() public virtual override {
        super.setUp();
        vm.warp(timeA);
        storeDelayedInclusions(numInclusionsA);
        vm.warp(timeB);
        storeDelayedInclusions(numInclusionsB);
        vm.warp(timeC);
        storeDelayedInclusions(numInclusionsC);
        vm.warp(timeD);
        storeDelayedInclusions(numInclusionsD);
    }

    function storeDelayedInclusions(uint256 numInclusions) public {
        for (uint256 i; i < numInclusions; ++i) {
            uint256[] memory blobIndices = new uint256[](1);
            // simulate a blob index
            blobIndices[0] = vm.randomUint(256);
            inclusionStore.publishDelayed(blobIndices);
        }
    }
}

contract StaggeredInclusionStateTest is StaggeredInclusionState {
    function test_processDueInclusions_NotDue() public {
        vm.prank(inbox);
        vm.warp(timeA);
        DelayedInclusionStore.Inclusion[] memory inclusions = inclusionStore.processDueInclusions();
        assertEq(inclusions.length, 0);
    }

    function test_processDueInclusions_RevertWhen_NotInbox() public {
        vm.warp(timeA + inclusionDelay);
        vm.expectRevert("Only inbox can process inclusions");
        inclusionStore.processDueInclusions();
    }

    function test_processDueInclusions_FirstPartDue() public {
        vm.startPrank(inbox);
        vm.warp(timeA + inclusionDelay);

        DelayedInclusionStore.Inclusion[] memory expectedInclusions =
            new DelayedInclusionStore.Inclusion[](numInclusionsA);
        for (uint256 i = 0; i < numInclusionsA; i++) {
            expectedInclusions[i] = IDelayedInclusionStore.Inclusion(readInclusionArray(i).blobRefHash);
        }
        emit DelayedInclusionStore.DelayedInclusionProcessed(expectedInclusions);

        DelayedInclusionStore.Inclusion[] memory inclusions = inclusionStore.processDueInclusions();

        assertEq(inclusions.length, numInclusionsA);
        assertEq(inclusions[0].blobRefHash, readInclusionArray(0).blobRefHash);
        assertEq(inclusions[numInclusionsA - 1].blobRefHash, readInclusionArray(numInclusionsA - 1).blobRefHash);
        vm.stopPrank();
    }

    function test_processDueInclusions_SecondPartDue() public {
        vm.startPrank(inbox);
        vm.warp(timeB + inclusionDelay);

        DelayedInclusionStore.Inclusion[] memory inclusions = inclusionStore.processDueInclusions();

        uint256 totalInclusions = numInclusionsA + numInclusionsB;
        assertEq(inclusions.length, totalInclusions);
        assertEq(inclusions[0].blobRefHash, readInclusionArray(0).blobRefHash);
        assertEq(inclusions[totalInclusions - 1].blobRefHash, readInclusionArray(totalInclusions - 1).blobRefHash);
        vm.stopPrank();
    }

    function test_processDueInclusions_ThirdPartDue() public {
        vm.startPrank(inbox);
        vm.warp(timeC + inclusionDelay);

        DelayedInclusionStore.Inclusion[] memory inclusions = inclusionStore.processDueInclusions();

        uint256 totalInclusions = numInclusionsA + numInclusionsB + numInclusionsC;
        assertEq(inclusions.length, totalInclusions);
        assertEq(inclusions[0].blobRefHash, readInclusionArray(0).blobRefHash);
        assertEq(inclusions[totalInclusions - 1].blobRefHash, readInclusionArray(totalInclusions).blobRefHash);
        vm.stopPrank();
    }

    function test_processDueInclusions_AllDue() public {
        vm.prank(inbox);
        vm.warp(timeD + inclusionDelay);

        DelayedInclusionStore.Inclusion[] memory inclusions = inclusionStore.processDueInclusions();

        uint256 totalInclusions = numInclusionsA + numInclusionsB + numInclusionsC + numInclusionsD;
        assertEq(inclusions.length, totalInclusions);
        assertEq(inclusions[0].blobRefHash, readInclusionArray(0).blobRefHash);
        assertEq(inclusions[totalInclusions - 1].blobRefHash, readInclusionArray(totalInclusions - 1).blobRefHash);
    }
}
