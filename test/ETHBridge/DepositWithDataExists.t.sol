// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BridgeSufficientlyCapitalized} from "./BridgeSufficientlyCapitalized.t.sol";
import {TransferRecipient} from "test/mocks/TransferRecipient.sol";

contract DepositWithDataExists is BridgeSufficientlyCapitalized {
    function setUp() public override {
        super.setUp();
        // Set the recipient to be a TransferRecipient contract
        deployCodeTo("TransferRecipient.sol", recipient);
    }

    // deposit 1 contains a valid call to recipient.someFunction(1234)
    function _depositIdx() internal pure override returns (uint256) {
        return 1;
    }
}
