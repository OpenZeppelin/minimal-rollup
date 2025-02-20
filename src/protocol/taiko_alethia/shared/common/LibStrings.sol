// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
@dev This is taken from Taiko's Alethia repo
(https://github.com/taikoxyz/taiko-mono/blob/taiko-alethia-client-v0.43.1/packages/protocol/contracts/shared/common/LibStrings.sol) 
    And does not include the full implementation of the contract. Instead only the signal service constant is included.
*/
/// @title LibStrings
/// @custom:security-contact security@taiko.xyz
library LibStrings {
    bytes32 internal constant B_SIGNAL_SERVICE = bytes32("signal_service");
}
