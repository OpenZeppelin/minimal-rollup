// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {DataFeed} from "src/protocol/DataFeed.sol";
import {IDataFeed} from "src/protocol/IDataFeed.sol";

contract DataFeedTest is Test {
    DataFeed feed;

    function setUp() public {
        feed = new DataFeed();
    }

    function testRevert_NoBlobs() public {
        vm.expectRevert();
        IDataFeed.HookQuery[] memory queries = new IDataFeed.HookQuery[](0);
        feed.publish(0, queries);
    }

    function test_EmptyBlobDoesNotRevert() public {
        IDataFeed.HookQuery[] memory queries = new IDataFeed.HookQuery[](0);
        feed.publish(1, queries);
    }
}
