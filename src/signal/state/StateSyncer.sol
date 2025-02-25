// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibTrieProof} from "../../libs/LibTrieProof.sol";
import {ISignalService} from "../ISignalService.sol";
import {IStateSyncer} from "./IStateSyncer.sol";

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

abstract contract StateSyncer is IStateSyncer {
    using SafeCast for uint256;

    address private immutable _signalService;

    mapping(uint64 chainId => uint64 publicationId) private _latestPublicationId;
    mapping(uint64 chainId => mapping(uint64 publicationId => bytes32 commitment)) private _commitmentAt;

    modifier onlySyncer() {
        _checkSyncer(msg.sender);
        _;
    }

    constructor(address signalService_) {
        _signalService = signalService_;
    }

    function syncSignal(uint64 chainId, uint64 publicationId, bytes32 commitment)
        public
        pure
        virtual
        returns (bytes32 signal)
    {
        return keccak256(abi.encode(chainId, publicationId, commitment));
    }

    function signalService() public view virtual returns (ISignalService) {
        return ISignalService(_signalService);
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

    function verifyCommitment(uint64 chainId, uint64 publicationId, bytes32 commitment, bytes[] calldata proof)
        public
        view
        returns (bool valid)
    {
        bytes32 slot = signalService().signalSlot(
            block.chainid.toUint64(), address(this), syncSignal(chainId, publicationId, commitment)
        );
        return LibTrieProof.verifyState(slot, syncSignal(chainId, publicationId, commitment), commitment, proof);
    }

    function syncState(uint64 chainId, uint64 publicationId, bytes32 commitment) external virtual onlySyncer {
        _syncState(chainId, publicationId, commitment);
    }

    function _syncState(uint64 chainId, uint64 publicationId, bytes32 commitment) internal virtual {
        if (latestPublicationId(chainId) < publicationId) {
            _latestPublicationId[chainId] = publicationId;
            _commitmentAt[chainId][publicationId] = commitment;
            signalService().sendSignal(syncSignal(chainId, publicationId, commitment));
            emit ChainDataSynced(chainId, publicationId, commitment);
        }
    }

    /// @dev Must revert if the caller is not an authorized syncer.
    function _checkSyncer(address caller) internal virtual;
}
