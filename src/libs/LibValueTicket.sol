// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "../libs/LibSignal.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev Library to create and verify value tickets per chain (source and destination), block number, sender, receiver.
///
/// Tickets can be used to bridge ETH or standard tokens (e.g. ERC20, ERC271, ERC1155).
library LibValueTicket {
    using SafeCast for uint256;
    using LibSignal for address;

    /// @dev The ticket is not valid (i.e. couldn't be verified)
    error InvalidTicket();

    /// @dev Unique ticket identifier.
    function ticketId(uint64 destinationChainId, uint64 blockNumber, address from, address to, uint256 value)
        internal
        view
        returns (bytes32 id)
    {
        return keccak256(abi.encodePacked(destinationChainId, blockNumber, from, to, value));
    }

    /// @dev Verifies if a ticket created on the `sourceChainId` at `blockNumber` by the receiver (`from`) is valid for
    /// the receiver `to` to claim `value` on this chain. It does so by performing an storage proof of `address(this)`
    /// on the source chain using `accountProof` and validating it against the network state `root` using `proof`.
    /// The `root` MUST be trusted.
    function verifyTicket(
        uint64 sourceChainId,
        uint64 blockNumber,
        address from,
        address to,
        uint256 value,
        bytes32 root,
        bytes[] calldata accountProof,
        bytes[] calldata proof
    ) internal view returns (bool verified, bytes32 id) {
        id = ticketId(block.chainid.toUint64(), blockNumber, from, to, value);
        (verified,) = address(this).verifySignal(root, sourceChainId, id, accountProof, proof);
        return (verified, id);
    }

    /// @dev Creates a ticket with `msg.value` ETH for the receiver (`to`) to claim on the `destinationChainId`.
    function createTicket(uint64 destinationChainId, address from, address to, uint256 value)
        internal
        payable
        returns (bytes32)
    {
        uint64 blockNumber = block.number.toUint64();
        bytes32 id = ticketId(destinationChainId, blockNumber, from, to, value);
        id.signal();
        return id;
    }

    /// @dev Reverts if a ticket was not created by `from` at `blockNumber` on `sourceChainId`. See `verifyTicket`.
    function checkTicket(
        uint64 sourceChainId,
        uint64 blockNumber,
        address from,
        address to,
        uint256 value,
        bytes32 root,
        bytes[] calldata accountProof,
        bytes[] calldata proof
    ) internal returns (bytes32) {
        (bool valid, bytes32 id) = verifyTicket(sourceChainId, blockNumber, from, to, value, root, accountProof, proof);
        require(valid, InvalidTicket());
        return id;
    }
}
