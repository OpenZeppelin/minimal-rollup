// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ISignalService} from "src/protocol/ISignalService.sol";

/// @dev To test the signal service, we need a mechanism to create a signal on one chain and prove it on another.
/// The command `just create-sample-signal-proof` will:
/// 1. Use anvil to set up the source chain
/// 2. Create a signal and the corresponding proof
/// 3. Output the relevant details of the source deployment and signal to the `SampleProof` contract.
/// This can be imported into the test suite, which verifies the behavior on the destination chain.
/// This interface describes the value from the source chain that need to be exposed to the test suite.
/// Note that the behavior on the source chain can be tested directly (without needing to construct a proof that can be
/// verified on a second chain)
interface ISampleProof {
    function getSignalServiceAddress() external returns (address);
    function getSignalProof() external returns (ISignalService.SignalProof memory);
    function getSignalDetails() external returns (address sender, bytes32 value);
    function getSlot() external returns (bytes32 slot);
}
