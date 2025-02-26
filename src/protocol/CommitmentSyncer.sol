// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "../libs/LibSignal.sol";
import {LibTrieProof} from "../libs/LibTrieProof.sol";
import {ICommitmentSyncer} from "./ICommitmentSyncer.sol";

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

abstract contract CommitmentSyncer is ICommitmentSyncer {
    using SafeCast for uint256;
    using LibSignal for bytes32;

    mapping(uint64 chainId => uint64 publicationId) private _latestPublicationId;
    mapping(uint64 chainId => mapping(uint64 publicationId => bytes32 commitment)) private _commitmentAt;

    modifier onlySyncer() {
        _checkSyncer(msg.sender);
        _;
    }

    function syncValue(uint64 chainId, uint64 publicationId, bytes32 commitment)
        public
        pure
        virtual
        returns (bytes32 value)
    {
        return keccak256(abi.encodePacked(chainId, publicationId, commitment));
    }

    function commitmentAt(uint64 chainId, uint64 publicationId) public view virtual returns (bytes32 commitment) {
        return _commitmentAt[chainId][publicationId];
    }

    function latestCommitment(uint64 chainId) public view virtual returns (bytes32 commitment) {
        return commitmentAt(chainId, latestPublicationId(chainId));
    }

    function latestPublicationId(uint64 chainId) public view virtual returns (uint64 publicationId) {
        return _latestPublicationId[chainId];
    }

    function verifyCommitment(
        uint64 chainId,
        uint64 publicationId,
        bytes32 commitment,
        bytes32 stateRoot,
        bytes[] calldata proof
    ) public view returns (bool valid) {
        bytes32 value = syncValue(chainId, publicationId, commitment);
        return LibTrieProof.verifyState(value.deriveSlot(), value, stateRoot, proof);
    }

    function syncCommitment(uint64 chainId, uint64 publicationId, bytes32 commitment) external virtual onlySyncer {
        _syncCommitment(chainId, publicationId, commitment);
    }

    function _syncCommitment(uint64 chainId, uint64 publicationId, bytes32 commitment) internal virtual {
        if (latestPublicationId(chainId) < publicationId) {
            _latestPublicationId[chainId] = publicationId;
            _commitmentAt[chainId][publicationId] = commitment;
            syncValue(chainId, publicationId, commitment).signal();
            emit CommitmentSynced(chainId, publicationId, commitment);
        }
    }

    /// @dev Must revert if the caller is not an authorized syncer.
    function _checkSyncer(address caller) internal virtual;
}
