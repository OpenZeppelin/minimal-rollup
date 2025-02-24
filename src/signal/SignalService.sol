// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../libs/LibTrieProof.sol";
import "./ISignalService.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

contract SignalService is
    ISignalService,
    AccessManaged,
    ReentrancyGuardTransient
{
    uint64 internal constant SIGNAL_SERVICE_ROLE =
        uint64(bytes32("signal_service"));
    uint64 internal constant SIGNAL_SERVICE_SYNCER_ROLE =
        uint64(bytes32("signal_service_syncer"));

    bytes32 internal constant SIGNAL_ROOT = keccak256("SIGNAL_ROOT");
    bytes32 internal constant STATE_ROOT = keccak256("STATE_ROOT");

    mapping(uint64 chainId => mapping(bytes32 kind => uint64 blockId))
        public topBlockId;

    mapping(bytes32 signalSlot => bool received) internal _receivedSignals;

    struct CacheAction {
        bytes32 rootHash;
        bytes32 signalRoot;
        uint64 chainId;
        uint64 blockId;
        bool isFullProof;
        bool isLastHop;
        CacheOption option;
    }

    error SS_EMPTY_PROOF();
    error SS_INVALID_HOPS_WITH_LOOP();
    error SS_INVALID_LAST_HOP_CHAINID();
    error SS_INVALID_MID_HOP_CHAINID();
    error SS_SIGNAL_NOT_FOUND();
    error SS_SIGNAL_NOT_RECEIVED();

    constructor(address _authority) AccessManaged(_authority) {}

    /// @dev Allow TaikoL2 to receive signals directly in its Anchor transaction.
    /// @param _signalSlots The signal slots to mark as received.
    function receiveSignals(
        bytes32[] calldata _signalSlots
    ) external restricted {
        for (uint256 i; i < _signalSlots.length; ++i) {
            _receivedSignals[_signalSlots[i]] = true;
        }
        emit SignalsReceived(_signalSlots);
    }

    /// @inheritdoc ISignalService
    function sendSignal(bytes32 _signal) external returns (bytes32) {
        return _sendSignal(msg.sender, _signal, _signal);
    }

    /// @inheritdoc ISignalService
    function syncChainData(
        uint64 _chainId,
        bytes32 _kind,
        uint64 _blockId,
        bytes32 _chainData
    ) external restricted returns (bytes32) {
        return _syncChainData(_chainId, _kind, _blockId, _chainData);
    }

    /// @inheritdoc ISignalService
    /// @dev This function may revert.
    function proveSignalReceived(
        uint64 _chainId,
        address _app,
        bytes32 _signal,
        bytes calldata _proof
    ) external virtual restricted nonReentrant returns (uint256 numCacheOps_) {
        CacheAction[] memory actions = _verifySignalReceived( // actions for caching
            _chainId,
            _app,
            _signal,
            _proof,
            true
        );

        for (uint256 i; i < actions.length; ++i) {
            numCacheOps_ += _cache(actions[i]);
        }
    }

    /// @inheritdoc ISignalService
    /// @dev This function may revert.
    function verifySignalReceived(
        uint64 _chainId,
        address _app,
        bytes32 _signal,
        bytes calldata _proof
    ) external view {
        _verifySignalReceived(_chainId, _app, _signal, _proof, false);
    }

    /// @inheritdoc ISignalService
    function isChainDataSynced(
        uint64 _chainId,
        bytes32 _kind,
        uint64 _blockId,
        bytes32 _chainData
    ) public view returns (bool) {
        require(_chainData != bytes32(0));
        bytes32 signal = signalForChainData(_chainId, _kind, _blockId);
        return _loadSignalValue(address(this), signal) == _chainData;
    }

    /// @inheritdoc ISignalService
    function isSignalSent(
        address _app,
        bytes32 _signal
    ) public view returns (bool) {
        return _loadSignalValue(_app, _signal) != 0;
    }

    /// @inheritdoc ISignalService
    function isSignalSent(bytes32 _signalSlot) public view returns (bool) {
        return _loadSignalValue(_signalSlot) != 0;
    }

    /// @inheritdoc ISignalService
    function getSyncedChainData(
        uint64 _chainId,
        bytes32 _kind,
        uint64 _blockId
    ) public view returns (uint64 blockId_, bytes32 chainData_) {
        blockId_ = _blockId != 0 ? _blockId : topBlockId[_chainId][_kind];

        if (blockId_ != 0) {
            bytes32 signal = signalForChainData(_chainId, _kind, blockId_);
            chainData_ = _loadSignalValue(address(this), signal);
            require(chainData_ != 0, SS_SIGNAL_NOT_FOUND());
        }
    }

    /// @inheritdoc ISignalService
    function signalForChainData(
        uint64 _chainId,
        bytes32 _kind,
        uint64 _blockId
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_chainId, _kind, _blockId));
    }

    /// @notice Returns the slot for a signal.
    /// @param _chainId The chainId of the signal.
    /// @param _app The address that initiated the signal.
    /// @param _signal The signal (message) that was sent.
    /// @return The slot for the signal.
    function getSignalSlot(
        uint64 _chainId,
        address _app,
        bytes32 _signal
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("SIGNAL", _chainId, _app, _signal));
    }

    function _verifyHopProof(
        uint64 _chainId,
        address _app,
        bytes32 _signal,
        bytes32 _value,
        HopProof memory _hop,
        address _signalService
    ) internal view virtual returns (bytes32) {
        require(_app != address(0));
        require(_signal != bytes32(0));
        require(_value != bytes32(0));

        return
            LibTrieProof.verifyMerkleProof(
                _hop.rootHash,
                _signalService,
                getSignalSlot(_chainId, _app, _signal),
                _value,
                _hop.accountProof,
                _hop.storageProof
            );
    }

    function _syncChainData(
        uint64 _chainId,
        bytes32 _kind,
        uint64 _blockId,
        bytes32 _chainData
    ) private returns (bytes32 signal_) {
        signal_ = signalForChainData(_chainId, _kind, _blockId);
        _sendSignal(address(this), signal_, _chainData);

        if (topBlockId[_chainId][_kind] < _blockId) {
            topBlockId[_chainId][_kind] = _blockId;
        }
        emit ChainDataSynced(_chainId, _blockId, _kind, _chainData, signal_);
    }

    function _sendSignal(
        address _app,
        bytes32 _signal,
        bytes32 _value
    ) private returns (bytes32 slot_) {
        require(_app != address(0));
        require(_signal != bytes32(0));
        require(_value != bytes32(0));

        slot_ = getSignalSlot(uint64(block.chainid), _app, _signal);
        assembly ("memory-safe") {
            sstore(slot_, _value)
        }
        emit SignalSent(_app, _signal, slot_, _value);
    }

    function _cache(
        CacheAction memory _action
    ) private returns (uint256 numCacheOps_) {
        // cache state root
        bool cacheStateRoot = _action.option == CacheOption.CACHE_BOTH ||
            _action.option == CacheOption.CACHE_STATE_ROOT;

        if (cacheStateRoot && _action.isFullProof && !_action.isLastHop) {
            numCacheOps_ = 1;
            _syncChainData(
                _action.chainId,
                STATE_ROOT,
                _action.blockId,
                _action.rootHash
            );
        }

        // cache signal root
        bool cacheSignalRoot = _action.option == CacheOption.CACHE_BOTH ||
            _action.option == CacheOption.CACHE_SIGNAL_ROOT;

        if (cacheSignalRoot && (_action.isFullProof || !_action.isLastHop)) {
            numCacheOps_ += 1;
            _syncChainData(
                _action.chainId,
                SIGNAL_ROOT,
                _action.blockId,
                _action.signalRoot
            );
        }
    }

    function _loadSignalValue(
        address _app,
        bytes32 _signal
    ) private view returns (bytes32) {
        require(_app != address(0));
        require(_signal != bytes32(0));
        bytes32 slot = getSignalSlot(uint64(block.chainid), _app, _signal);
        return _loadSignalValue(slot);
    }

    function _loadSignalValue(
        bytes32 _signalSlot
    ) private view returns (bytes32 value_) {
        assembly ("memory-safe") {
            value_ := sload(_signalSlot)
        }
    }

    function _verifySignalReceived(
        uint64 _chainId,
        address _app,
        bytes32 _signal,
        bytes calldata _proof,
        bool _prepareCaching
    ) private view returns (CacheAction[] memory actions) {
        require(_app != address(0));
        require(_signal != bytes32(0));
        if (_proof.length == 0) {
            require(
                _receivedSignals[getSignalSlot(_chainId, _app, _signal)],
                SS_SIGNAL_NOT_RECEIVED()
            );
            return new CacheAction[](0);
        }

        HopProof[] memory hopProofs = abi.decode(_proof, (HopProof[]));
        if (hopProofs.length == 0) revert SS_EMPTY_PROOF();

        uint64[] memory trace = new uint64[](hopProofs.length - 1);

        actions = new CacheAction[](_prepareCaching ? hopProofs.length : 0);

        uint64 chainId = _chainId;
        address app = _app;
        bytes32 signal = _signal;
        bytes32 value = _signal;

        require(
            authority().hasRole(SIGNAL_SERVICE_ROLE, address(this)),
            SS_INVALID_MID_HOP_CHAINID()
        );

        HopProof memory hop;
        bytes32 signalRoot;
        bool isFullProof;
        bool isLastHop;

        for (uint256 i; i < hopProofs.length; ++i) {
            hop = hopProofs[i];

            for (uint256 j; j < i; ++j) {
                if (trace[j] == hop.chainId) revert SS_INVALID_HOPS_WITH_LOOP();
            }

            signalRoot = _verifyHopProof(
                chainId,
                app,
                signal,
                value,
                hop,
                signalService
            );
            isLastHop = i == trace.length;
            if (isLastHop) {
                if (hop.chainId != block.chainid)
                    revert SS_INVALID_LAST_HOP_CHAINID();
                signalService = address(this);
            } else {
                trace[i] = hop.chainId;

                require(
                    hop.chainId != 0 &&
                        hop.chainId != block.chainId &&
                        authority().hasRole(SIGNAL_SERVICE_ROLE, address(this)),
                    SS_INVALID_MID_HOP_CHAINID()
                );
            }

            isFullProof = hop.accountProof.length != 0;

            if (_prepareCaching) {
                actions[i] = CacheAction(
                    hop.rootHash,
                    signalRoot,
                    chainId,
                    hop.blockId,
                    isFullProof,
                    isLastHop,
                    hop.cacheOption
                );
            }

            signal = signalForChainData(
                chainId,
                isFullProof ? STATE_ROOT : SIGNAL_ROOT,
                hop.blockId
            );
            value = hop.rootHash;
            chainId = hop.chainId;
            app = signalService;
        }

        require(
            value != 0 && value == _loadSignalValue(address(this), signal),
            SS_SIGNAL_NOT_FOUND()
        );
    }
}
