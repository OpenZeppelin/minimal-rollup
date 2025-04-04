// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibTrieProof} from "../libs/LibTrieProof.sol";

import {IETHBridge} from "./IETHBridge.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

/// @dev Abstract ETH bridging contract to send native ETH to other chains using storage proofs.
///
/// IMPORTANT: No recovery mechanism is implemented in case an account creates a deposit that can't be claimed.
abstract contract ETHBridge is IETHBridge {
    using StorageSlot for bytes32;

    mapping(bytes32 id => bool claimed) private _claimed;

    /// Incremental nonce to generate unique deposit IDs.
    uint256 private _globalDepositNonce;

    /// @inheritdoc IETHBridge
    function claimed(bytes32 id) public view virtual returns (bool) {
        return _claimed[id];
    }

    /// @inheritdoc IETHBridge
    function getDepositId(ETHDeposit memory deposit) public view virtual returns (bytes32 id) {
        return _generateId(deposit);
    }

    /// @inheritdoc IETHBridge
    // TODO: Possibly make this accept ETHDEeposit struct as input
    function depositETH(uint64 chainId, address to, bytes memory data) public payable virtual returns (bytes32 id) {
        ETHDeposit memory deposit = ETHDeposit(chainId, _globalDepositNonce, msg.sender, to, msg.value, data);
        id = _generateId(deposit);
        unchecked {
            ++_globalDepositNonce;
        }
        emit ETHDepositMade(id, deposit);
    }

    /// @inheritdoc IETHBridge
    function claimDeposit(
        ETHDeposit memory deposit,
        uint256 height,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) external virtual returns (bytes32 id);

    /// @dev Processes deposit claim by id.
    /// @param id Identifier of the deposit
    /// @param deposit Deposit to process
    function _processClaimDepositWithId(bytes32 id, ETHDeposit memory deposit) internal virtual {
        require(!claimed(id), AlreadyClaimed());
        _claimed[id] = true;
        _sendETH(deposit.to, deposit.amount, deposit.data);
        emit ETHDepositClaimed(id, deposit);
    }

    /// @dev Function to transfer ETH to the receiver but ignoring the returndata.
    /// @param to Address to send the ETH to
    /// @param value Amount of ETH to send
    /// @param data Data to send to the receiver
    function _sendETH(address to, uint256 value, bytes memory data) internal virtual returns (bool success) {
        assembly ("memory-safe") {
            // CHECK: use staticcall?
            success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
        }
        require(success, FailedClaim());
    }

    /// @dev Generates a unique ID for a deposit.
    /// @param deposit Deposit to generate an ID for
    function _generateId(ETHDeposit memory deposit) internal pure returns (bytes32) {
        return keccak256(abi.encode(deposit));
    }
}
