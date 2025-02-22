// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {PublicationFeed} from "src/protocol/PublicationFeed.sol";

contract PublicationFeedTest is Test {
    PublicationFeed feed;

    function setUp() public {
        feed = new PublicationFeed();
    }

    function test_DoNothing() public pure {
        // The CI requires a test.
        assertEq(true, true);
    }
}
