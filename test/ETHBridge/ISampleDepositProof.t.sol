// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

/// @dev This interface serves the same purpose as ISampleProof (in that it records values from the source chain that
/// should be passed to the test suite), but it contains additional values required to test the ETHBridge contract.
interface ISampleDepositProof {
    function getSignalServiceAddress() external returns (address);
    function getBridgeAddress() external returns (address);
    function getStateRoot() external returns (bytes32);
    function getBlockHash() external returns (bytes32);
    function getDepositSignalProof(uint256 idx) external returns (ISignalService.SignalProof memory);
    function getEthDeposit(uint256 idx) external returns (IETHBridge.ETHDeposit memory deposit);
    function getDepositInternals(uint256 idx) external returns (bytes32 slot, bytes32 id);
    function getNumberOfProofs() external view returns (uint256 count);
}
