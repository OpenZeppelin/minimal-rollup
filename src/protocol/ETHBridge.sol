// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibTrieProof} from "../libs/LibTrieProof.sol";

import {IETHBridge} from "./IETHBridge.sol";
import {SlotDerivation} from "@openzeppelin/contracts/utils/SlotDerivation.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev Abstract ETH bridging contract to send native ETH to other chains using storage proofs.
///
/// IMPORTANT: No recovery mechanism is implemented in case an account creates a deposit that can't be claimed.
abstract contract ETHBridge is IETHBridge {
    using SafeCast for uint256;
    using StorageSlot for bytes32;
    using SlotDerivation for *;

    mapping(bytes32 id => bool) _claimed;

    /// @inheritdoc IETHBridge
    function claimed(bytes32 id) public view virtual returns (bool) {
        return _claimed[id];
    }

    /// @inheritdoc IETHBridge
    function getDepositId(ETHDeposit memory deposit) public view virtual returns (bytes32 id) {
        return _generateId(deposit);
    }

    /// @inheritdoc IETHBridge
    function depositETH(uint64 chainId, address to, bytes memory data) public payable virtual returns (bytes32 id) {
        address sender = msg.sender;
        uint64 nonce = _useNonce(sender).toUint64();
        ETHDeposit memory deposit = ETHDeposit(chainId, nonce, sender, to, msg.value, data);
        id = _generateId(deposit);
        emit ETHDepositMade(id, deposit);
    }

    /// @inheritdoc IETHBridge
    function claimDeposit(ETHDeposit memory deposit, bytes[] memory accountProof, bytes[] memory storageRoot)
        external
        virtual
        returns (bytes32 id);

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

    /// @dev Processes the generic deposit claim logic.
    /// @param id Identifier of the deposit
    /// @param deposit Deposit to process
    function _processClaimDepositWithId(bytes32 id, ETHDeposit memory deposit) internal {
        require(!claimed(id), AlreadyClaimed());
        _claimed[id] = true;
        _sendETH(deposit.to, deposit.amount, deposit.data);
        emit ETHDepositClaimed(id, deposit);
    }

    /// @dev Generates a unique ID for a deposit.
    /// @param deposit Deposit to generate an ID for
    function _generateId(ETHDeposit memory deposit) internal pure returns (bytes32) {
        return keccak256(abi.encode(deposit));
    }

    /// @dev Consumes a nonce and returns the current value and increments nonce.
    function _useNonce(address account) internal returns (uint256) {
        // For each account, the nonce has an initial value of 0, can only be incremented by one, and cannot be
        // decremented or reset. This guarantees that the nonce never overflows.

        unchecked {
            // It is important to do x++ and not ++x here.
            // slot: keccak256(abi.encode(uint256(keccak256("LibValueTicket.nonces")) - 1)) & ~bytes32(uint256(0xff))
            return 0x23c95d7a21dec6ba744555d361d2572ad62017f33fd3da51a4ffa8cde254e900.deriveMapping(account)
                .getUint256Slot().value++;
        }
    }
}
