// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DataFeed} from "../../src/protocol/DataFeed.sol";
import {TransientSlot} from "@openzeppelin/contracts/utils/TransientSlot.sol";

contract DataFeedMock is DataFeed {
    using TransientSlot for *;

    function unsafeSetTransactionGuard(bool value) external {
        _TRANSACTION_GUARD.asBoolean().tstore(value);
    }
}
