// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

/// @dev This interface serves the same purpose as ISampleProof (in that it records values from the source chain that
/// should be passed to the test suite), but it contains additional values required to test the ETHBridge contract.
interface ISampleDepositProof {
    function getSourceAddresses() external returns (address signalService, address bridge);
    function getDepositSignalProof() external returns (ISignalService.SignalProof memory);
    function getEthDeposit() external pure returns (IETHBridge.ETHDeposit memory deposit);
    function getDepositInternals() external pure returns (bytes32 slot, bytes32 id);
}
