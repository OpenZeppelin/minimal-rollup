// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "../libs/LibSignal.sol";
import {LibTrieProof} from "../libs/LibTrieProof.sol";
import {INativeTokenBridge} from "./INativeTokenBridge.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract NativeTokenBridge is INativeTokenBridge {
    using SafeCast for uint256;
    using LibSignal for bytes32;

    mapping(bytes32 id => bool) _claimed;

    function claimed(bytes32 id) external view returns (bool) {
        return _claimed[id];
    }

    function ticketId(uint64 chainId, uint64 blockNumber, address from, address to, uint256 value)
        public
        view
        virtual
        returns (bytes32 id)
    {
        return keccak256(abi.encodePacked(chainId, blockNumber, from, to, value));
    }

    function verifyTicket(
        uint64 sourceChainId,
        uint64 blockNumber,
        address from,
        address to,
        uint256 value,
        bytes32 root,
        bytes[] calldata proof
    ) public view virtual returns (bool verified, bytes32 id) {
        id = ticketId(sourceChainId, blockNumber, from, to, value);
        return (LibTrieProof.verifyState(id.deriveSlot(), id, root, proof), id);
    }

    function createTicket(address to) external payable virtual {
        address from = msg.sender;
        uint64 blockNumber = block.number.toUint64();
        ticketId(block.chainid.toUint64(), blockNumber, from, to, msg.value).signal();
        emit Ticket(blockNumber, from, to, msg.value);
    }

    function claimTicket(
        uint64 sourceChainId,
        uint64 blockNumber,
        address from,
        address to,
        uint256 value,
        bytes32 root,
        bytes[] calldata proof
    ) external virtual {
        bytes32 id = _checkClaimTicket(sourceChainId, blockNumber, from, to, value, root, proof);
        _claimed[id] = true;
        _sendNativeValue(to, value);
    }

    function _checkClaimTicket(
        uint64 sourceChainId,
        uint64 blockNumber,
        address from,
        address to,
        uint256 value,
        bytes32 root,
        bytes[] calldata proof
    ) internal virtual returns (bytes32 id) {
        bool valid;
        (valid, id) = verifyTicket(sourceChainId, blockNumber, from, to, value, root, proof);
        require(!claimed(id), AlreadyClaimed());
        require(valid, InvalidTicket());
    }

    function _sendNativeValue(address to, uint256 value) private returns (bool success) {
        assembly ("memory-safe") {
            success := call(gas(), to, value, 0, 0, 0, 0)
        }
        require(success, FailedClaim());
    }
}
