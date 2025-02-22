// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

///@title ISignalService
///@notice Interface for sending signals and verifying signals for cross-chain communication.
interface ISignalService {
    ///@notice Emitted for each signal
    ///@param signal The signal value
    ///@param idx The index of the signal
    ///@param blockNumber The block number of the signal
    event Signal(bytes32 indexed signal, uint256 indexed idx, uint256 indexed blockNumber);

    /// @notice Sends a signal and update MMR peaks
    /// @param signal The signal value
    ///@dev This function should be called on the source chain
    function send(bytes32 signal) external;

    /// @notice Verifies a signal has been sent using a merkle proof
    /// @param idx The index of the signal
    /// @param signal The signal value
    /// @param proof The merkle proof of the signal
    ///@dev This function should be called on the destination chain
    function verify(uint256 idx, bytes32 signal, bytes32[] memory proof) external view;
}
