// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DataFeed} from "../../src/protocol/DataFeed.sol";
import {Inbox} from "../../src/protocol/Inbox.sol";
import {VerifierMock} from "../mocks/VerifierMock.sol";
import {Test} from "forge-std/Test.sol";

contract InboxTest is Test {
    Inbox inbox;
    DataFeed dataFeed;
    VerifierMock verifierMock;

    function setUp() public virtual {
        dataFeed = new DataFeed();
        verifierMock = new VerifierMock();
        inbox = new Inbox(
            100,
            keccak256("genesis"),
            address(dataFeed),
            address(verifierMock)
        );
    }

    function test_proveBetween(
        uint256 end,
        bytes32 checkpoint,
        bytes calldata proof
    ) external {
        uint256 start = 0;
        end = bound(end, start + 1, 10_000); // Avoid out-of-gas
        for (uint256 i; i < end; i++) dataFeed.publish(1);

        vm.expectCall(
            address(verifierMock),
            abi.encodeCall(
                VerifierMock.verifyProof,
                (
                    dataFeed.getPublicationHash(start),
                    dataFeed.getPublicationHash(end),
                    inbox.getCheckpoint(start),
                    checkpoint,
                    proof
                )
            )
        );
        inbox.proveBetween(start, end, checkpoint, proof);

        assertEq(inbox.getCheckpoint(end), checkpoint);
        assertEq(inbox.checkpointsCount(), end);
    }
}
