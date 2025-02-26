// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "../libs/LibSignal.sol";
import {LibTrieProof} from "../libs/LibTrieProof.sol";

import {LibValueTicket} from "../libs/LibValueTicket.sol";
import {IETHBridge} from "./IETHBridge.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev Bridge implementation to send native ETH to other chains using storage proofs.
contract ETHBridge is IETHBridge {
    using SafeCast for uint256;
    using LibSignal for *;
    using LibValueTicket for uint64;

    mapping(bytes32 id => bool) _claimed;

    /// @inheritdoc IETHBridge
    function claimed(bytes32 id) public view virtual returns (bool) {
        return _claimed[id];
    }

    /// @inheritdoc IETHBridge
    function ticketId(uint64 destinationChainId, uint64 blockNumber, address from, address to, uint256 value)
        public
        view
        virtual
        returns (bytes32 id)
    {
        return destinationChainId.ticketId(blockNumber, from, to, value);
    }

    /// @inheritdoc IETHBridge
    function verifyTicket(
        uint64 sourceChainId,
        uint64 blockNumber,
        address from,
        address to,
        uint256 value,
        bytes32 root,
        bytes[] calldata accountProof,
        bytes[] calldata proof
    ) public view virtual returns (bool verified, bytes32 id) {
        return sourceChainId.verifyTicket(blockNumber, from, to, value, root, accountProof, proof);
    }

    /// @inheritdoc IETHBridge
    function createTicket(uint64 destinationChainId, address to) external payable virtual {
        address from = msg.sender;
        uint256 value = msg.value;
        destinationChainId.createTicket(from, to, value);
        emit ETHTicket(destinationChainId, blockNumber, msg.sender, to, msg.value);
    }

    /// @inheritdoc IETHBridge
    function claimTicket(
        uint64 sourceChainId,
        uint64 blockNumber,
        address from,
        address to,
        uint256 value,
        bytes32 root,
        bytes[] calldata accountProof,
        bytes[] calldata proof
    ) external virtual {
        _claimed[sourceChainId.checkTicket(blockNumber, from, to, value, root, accountProof, proof)] = true;
        _sendETH(to, value);
    }

    /// @dev Function to transfer ETH to the receiver but ignoring the returndata.
    function _sendETH(address to, uint256 value) private returns (bool success) {
        assembly ("memory-safe") {
            success := call(gas(), to, value, 0, 0, 0, 0)
        }
        require(success, FailedClaim());
    }
}
