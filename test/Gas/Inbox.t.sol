// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BlobRefRegistry} from "../../src/blobs/BlobRefRegistry.sol";
import {IBlobRefRegistry} from "../../src/blobs/IBlobRefRegistry.sol";

import {ILookahead} from "../../src/protocol/ILookahead.sol";
import {IProposerFees} from "../../src/protocol/IProposerFees.sol";
import {TaikoInbox} from "../../src/protocol/taiko_alethia/TaikoInbox.sol";

import {MockProposerFees} from "../mocks/MockProposerFee.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import "forge-std/Test.sol";

///@dev script to test gas consumption of TaikoInbox.publish
contract TaikoInboxTest is Test {
    TaikoInbox taikoInbox;
    BlobRefRegistry blobRefRegistry;

    address lookaheadAddr = address(0);
    uint256 maxAnchorBlockIdOffset = uint256(10);
    uint256 inclusionDelay = uint256(10000000);

    function setUp() public {
        blobRefRegistry = new BlobRefRegistry();
        taikoInbox = new TaikoInbox(lookaheadAddr, address(blobRefRegistry), maxAnchorBlockIdOffset, inclusionDelay);
    }

    function test_gas_TaikoPublishFunction() public ProposeMultiplePublications(10) {
        uint256 numPublications = 20;
        vm.startSnapshotGas("publish");
        _publishMultiplePublications(numPublications);
        uint256 publishGas = vm.stopSnapshotGas("publish");
        uint256 gasPerPublication = publishGas / numPublications;
        string memory str = string(
            abi.encodePacked(
                "{",
                "num_publications:",
                Strings.toString(numPublications),
                "," "\naverage_gas_used_publish: ",
                Strings.toString(gasPerPublication),
                "}"
            )
        );

        console2.log(str);
        vm.writeFile("./gas-reports/minimal_inbox_publish.json", str);
    }

    ///@dev Ensure same state as tiako tests where multiple publications are made before testing gas usage
    modifier ProposeMultiplePublications(uint256 numPublications) {
        _publishMultiplePublications(numPublications);
        _;
    }

    function _publishMultiplePublications(uint256 numPublications) internal {
        vm.roll(maxAnchorBlockIdOffset);
        uint256 nBlobs = 1;
        uint64 baseAnchorBlockId = uint64(block.number - 1);

        bytes32[] memory blobHashes = new bytes32[](1);
        blobHashes[0] = keccak256(abi.encodePacked("txList"));

        vm.blobhashes(blobHashes);

        for (uint256 i = 0; i < numPublications; i++) {
            taikoInbox.publish(nBlobs, baseAnchorBlockId);
        }
    }
}
