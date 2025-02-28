// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibTrieProof} from "../libs/LibTrieProof.sol";

import {LibValueTicket} from "../libs/LibValueTicket.sol";
import {IETHBridge} from "./IETHBridge.sol";
import {ISignalService} from "./ISignalService.sol";

/// @dev Bridge implementation to send native ETH to other chains using storage proofs.
///
/// IMPORTANT: No recovery mechanism is implemented in case an account creates a ticket that can't be claimed. Consider
/// implementing one on top of this bridge for more specific use cases.
contract ETHBridge is IETHBridge {
    using LibValueTicket for LibValueTicket.ValueTicket;

    address public immutable signalService;

    mapping(bytes32 id => bool) _claimed;

    constructor(address _signalService) {
        signalService = _signalService;
    }

    /// @inheritdoc IETHBridge
    function claimed(bytes32 id) public view virtual returns (bool) {
        return _claimed[id];
    }

    /// @inheritdoc IETHBridge
    function ticketId(LibValueTicket.ValueTicket memory ticket) public view virtual returns (bytes32 id) {
        return ticket.id();
    }

    /// @inheritdoc IETHBridge
    function verifyTicket(
        LibValueTicket.ValueTicket memory ticket,
        bytes32 root,
        bytes[] memory accountProof,
        bytes[] memory proof
    ) public view virtual returns (bool verified, bytes32 id) {
        return ticket.verifyTicket(signalService, root, accountProof, proof);
    }

    /// @inheritdoc IETHBridge
    function createTicket(uint64 chainId, address to) external payable virtual {
        emit ETHTicket(LibValueTicket.createTicket(chainId, msg.sender, to, msg.value));
    }

    /// @inheritdoc IETHBridge
    function createFastTicket(uint64 chainId, address to) external payable virtual {
        emit FastETHTicket(LibValueTicket.createFastTicket(chainId, msg.sender, to, msg.value, signalService));
    }

    /// @inheritdoc IETHBridge
    function claimTicket(
        LibValueTicket.ValueTicket memory ticket,
        bytes32 root,
        bytes[] memory accountProof,
        bytes[] memory proof
    ) external virtual {
        bytes32 id_ = ticket.checkTicket(signalService, root, accountProof, proof);
        require(!claimed(id_), AlreadyClaimed());
        _claimed[id_] = true;
        _sendETH(ticket.to, ticket.value);
        emit ETHTicketClaimed(ticket);
    }

    /// @dev Function to transfer ETH to the receiver but ignoring the returndata.
    function _sendETH(address to, uint256 value) private returns (bool success) {
        assembly ("memory-safe") {
            success := call(gas(), to, value, 0, 0, 0, 0)
        }
        require(success, FailedClaim());
    }
}
