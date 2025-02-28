// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "../libs/LibSignal.sol";
import {ISignalService} from "../protocol/ISignalService.sol";
import {SlotDerivation} from "@openzeppelin/contracts/utils/SlotDerivation.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev Library to create and verify value tickets per chain (source and destination), nonce, sender, receiver.
///
/// Tickets can be used to bridge ETH or standard tokens (e.g. ERC20, ERC271, ERC1155) with the only condition of having
/// the same contract deployed on both chains and a trusted source of a state root.
library LibValueTicket {
    using SafeCast for uint256;
    using StorageSlot for bytes32;
    using LibSignal for *;
    using SlotDerivation for *;

    struct ValueTicket {
        uint64 chainId;
        uint64 nonce;
        address from;
        address to;
        uint256 value;
    }

    /// @dev The ticket is not valid (i.e. couldn't be verified)
    error InvalidTicket();

    /// @dev Unique ticket identifier.
    function id(ValueTicket memory ticket) internal pure returns (bytes32 _id) {
        return keccak256(abi.encode(ticket));
    }

    /// @dev Verifies that a ticket created with `nonce` by the receiver (`from`) is valid for the receiver (`to`)
    /// to claim `value` on this chain. It does so by performing an storage proof of `address(this)` on the source chain
    /// using `accountProof` and validating it against the network state `root` using `proof`.
    /// The `root` MUST be trusted.
    /// @dev For L1->L2 same slot signalling this should be called with no accountProof. In this case the signal will be
    /// verified against the receivedSignals mapping in the SignalService (filled by the proposer)
    function verifyTicket(
        ValueTicket memory ticket,
        address signalService,
        bytes32 root,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) internal view returns (bool verified, bytes32 _id) {
        _id = id(ticket);
        if (accountProof.length == 0) {
            ISignalService(signalService).verifySignal(
                address(this), root, ticket.chainId, _id, accountProof, storageProof
            );
            // true because call will revert otherwise
            return (true, _id);
        }
        (verified,) = address(this).verifySignal(root, ticket.chainId, _id, accountProof, storageProof);
        return (verified, _id);
    }

    /// @dev Creates a ticket with `msg.value` ETH for the receiver (`to`) to claim on the `destinationChainId`.
    function createTicket(uint64 destinationChainId, address from, address to, uint256 value)
        internal
        returns (ValueTicket memory ticket)
    {
        ticket = ValueTicket(destinationChainId, _useNonce(from).toUint64(), from, to, value);
        bytes32 _id = id(ticket);
        _id.signal();
        return ticket;
    }

    /// @dev Creates a ticket with `msg.value` ETH for the receiver (`to`) to claim on the `destinationChainId`.
    /// This redeamable within the same slot.
    /// @dev This is only for L1->L2 bridging
    function createFastTicket(uint64 destinationChainId, address from, address to, uint256 value, address signalService)
        internal
        returns (ValueTicket memory)
    {
        ticket = ValueTicket(destinationChainId, _useNonce(from).toUint64(), from, to, value);
        bytes32 _id = id(ticket);
        ISignalService(signalService).sendSignal(_id);
        return ticket;
    }

    /// @dev Reverts if a ticket was not created by `from` with `nonce` on `chainId`. See `verifyTicket`.
    function checkTicket(
        ValueTicket memory ticket,
        address signalService,
        bytes32 root,
        bytes[] memory accountProof,
        bytes[] memory proof
    ) internal view returns (bytes32) {
        (bool valid, bytes32 _id) = verifyTicket(ticket, signalService, root, accountProof, proof);
        require(valid, InvalidTicket());
        return _id;
    }

    /// @dev Consumes a nonce and returns the current value and increments nonce.
    function _useNonce(address account) private returns (uint256) {
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
