// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ISignaler {
    /// @notice Represents a single call within a batch.
    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    function executeBatch(Call[] calldata calls) external;
    function executeBatchWithSig(Call[] calldata calls, bytes calldata signature) external;
    function setSignalService(address signalService_) external;
    function signalService() external view returns (address);
    function nonce() external view returns (uint256);

    /// @notice Emitted for every individual call executed.
    event CallExecuted(address indexed sender, address indexed to, uint256 value, bytes data);
    /// @notice Emitted when a full batch is executed.
    event BatchExecuted(uint256 indexed nonce, Call[] calls);

    // errors
    error NotOwner();
    error InvalidSignature();
    error InvalidNonce();
    error CallReverted();
}
