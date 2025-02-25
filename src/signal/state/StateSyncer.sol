// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibTrieProof} from "../../libs/LibTrieProof.sol";
import {ISignalService} from "../ISignalService.sol";
import {IStateSyncer} from "./IStateSyncer.sol";

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

abstract contract StateSyncer is IStateSyncer {
    using SafeCast for uint256;

    address private immutable _signalService;

    mapping(uint64 chainId => uint64 blockNumber) private _latestBlock;
    mapping(uint64 chainId => mapping(uint64 blockNumber => bytes32 root)) private _stateAt;

    modifier onlySyncer() {
        _checkSyncer(msg.sender);
        _;
    }

    constructor(address signalService_) {
        _signalService = signalService_;
    }

    function syncSignal(uint64 chainId, uint64 blockNumber, bytes32 root)
        public
        pure
        virtual
        returns (bytes32 signal)
    {
        return keccak256(abi.encode(chainId, blockNumber, root));
    }

    function signalService() public view virtual returns (ISignalService) {
        return ISignalService(_signalService);
    }

    function stateAt(uint64 chainId, uint64 blockNumber) public view virtual returns (bytes32 root) {
        return _stateAt[chainId][blockNumber];
    }

    function latestState(uint64 chainId) public view virtual returns (bytes32 root) {
        return stateAt(chainId, latestBlock(chainId));
    }

    function latestBlock(uint64 chainId) public view virtual returns (uint64 blockNumber) {
        return _latestBlock[chainId];
    }

    function verifyState(uint64 chainId, uint64 blockNumber, bytes32 root, bytes[] calldata proof)
        public
        view
        returns (bool valid)
    {
        bytes32 slot =
            signalService().signalSlot(block.chainid.toUint64(), address(this), syncSignal(chainId, blockNumber, root));
        return LibTrieProof.verifyState(slot, syncSignal(chainId, blockNumber, root), root, proof);
    }

    function syncState(uint64 chainId, uint64 blockNumber, bytes32 root) external virtual onlySyncer {
        _syncState(chainId, blockNumber, root);
    }

    function _syncState(uint64 chainId, uint64 blockNumber, bytes32 root) internal virtual {
        if (latestBlock(chainId) < blockNumber) {
            _latestBlock[chainId] = blockNumber;
            _stateAt[chainId][blockNumber] = root;
            signalService().sendSignal(syncSignal(chainId, blockNumber, root));
            emit ChainDataSynced(chainId, blockNumber, root);
        }
    }

    /// @dev Must revert if the caller is not an authorized syncer.
    function _checkSyncer(address caller) internal virtual;
}
