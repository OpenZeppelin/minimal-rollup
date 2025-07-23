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

/// @title DeployTaikoInbox
/// @notice Script to deploy the TaikoInbox contract
contract TaikoInboxTest is Test {
    TaikoInbox taikoInbox;
    BlobRefRegistry blobRefRegistry;

    address lookaheadAddr = address(0);
    uint256 maxAnchorBlockIdOffset = uint256(10);
    uint256 inclusionDelay = uint256(10000000);

    function setUp() public {
        MockProposerFees mockProposerFees = new MockProposerFees();
        blobRefRegistry = new BlobRefRegistry();
        taikoInbox = new TaikoInbox(
            lookaheadAddr, address(blobRefRegistry), maxAnchorBlockIdOffset, address(mockProposerFees), inclusionDelay
        );
    }

    function test_gas_TaikoPublishFunction() public {
        uint256[] memory blobIndices = new uint256[](1);
        blobIndices[0] = 0;

        bytes32[] memory blobHashes = new bytes32[](1);
        blobHashes[0] = keccak256(abi.encode(0));

        vm.blobhashes(blobHashes);
        blobRefRegistry.registerRef(blobIndices);

        vm.roll(20);
        vm.startSnapshotGas("publish");
        taikoInbox.publish(1, 16);
        uint256 gas = vm.stopSnapshotGas("proposeBatch");
        string memory str = string(
            abi.encodePacked(
                "See `test_gas_TaikoPublishFunction` in Inbox.t.sol\n", "\nGas for publication: ", Strings.toString(gas)
            )
        );

        console2.log(str);
        vm.writeFile("./gas-reports/taiko_inbox_publish.txt", str);
    }
}
