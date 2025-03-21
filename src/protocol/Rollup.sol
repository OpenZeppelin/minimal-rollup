// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IRollup} from "./interfaces/IRollup.sol";

import {LibSignal} from "../libs/LibSignal.sol";

/// @dev Implementation of {IRollup}.
///
/// Given every rollup often requires a mechanism for L1 <> L2 communication, this rollup contract provides
/// an interface to emit signals, which are namespaced values written permanently to the contract storage (see
/// {LibSignal}). These signals are a simple primitive other contracts can use to build cross-chain applications.
///
/// For convenience, checkpoints are signalled when proposed and proven (see {toProvenSignal}). This allows
/// off-chain clients to monitor the rollup's state by watching the {IRollup-Proven} event. To avoid duplicate events,
/// the {SignalSent} event is skipped when calling `propose`.
///
/// An implementation of the {isValidTransition} and the {toCheckpoint} functions must be provided by a derived
/// contract, which define the proving scheme and how to produce a checkpoint from a publication. Also, consider the
/// following for a production-ready rollup:
///
/// - Restrict the right to post a prove for a publication. (i.e. override the {prove} function).
/// - Restrict the right to propose a publication (i.e. override the {propose} function).
///
/// Naturally, both can develop independent markets. One as an auction for provers to bid for a period to post proofs,
/// and the other as a market for proposers to bid for the right to propose a publication (allowing them to extract
/// MEV or issue preconfirmations).
abstract contract Rollup is IRollup {
    using LibSignal for bytes32;

    event SignalSent(bytes32 indexed value);

    bytes32 private _latestCheckpoint;

    /// @dev Initializes the rollup with a genesis checkpoint describing the initial state of the rollup.
    constructor(bytes32 genesisCheckpoint) {
        _latestCheckpoint = genesisCheckpoint;
    }

    /// @dev Given a checkpoint is signaled when proposed, this function returns the signal id for a proven checkpoint.
    function toProvenSignal(bytes32 checkpoint) public view virtual returns (bytes32) {
        return checkpoint.deriveSlot();
    }

    /// @inheritdoc IRollup
    function latestCheckpoint() public view virtual returns (bytes32) {
        return _latestCheckpoint;
    }

    /// @inheritdoc IRollup
    function proposed(bytes calldata publication) public view override returns (bool) {
        return signalSent(toCheckpoint(publication));
    }

    /// @inheritdoc IRollup
    function proven(bytes calldata publication) public view returns (bool) {
        return signalSent(toProvenSignal(toCheckpoint(publication)));
    }

    /// @inheritdoc IRollup
    function signalSent(bytes32 value) public view returns (bool) {
        return value.signaled();
    }

    /// @inheritdoc IRollup
    function isValidTransition(bytes32 from, bytes32 target, bytes memory proof) public view virtual returns (bool);

    /// @inheritdoc IRollup
    function toCheckpoint(bytes memory publication) public view virtual returns (bytes32);

    /// @dev See {IRollup-propose}.
    ///
    /// Consider restricting the right to propose a publication by overriding this function.
    /// Perhaps by calling an {ILookahead} contract:
    ///
    /// ```solidity
    /// function propose(bytes memory publication) external override {
    ///     require(lookahead.isCurrentPreconfer(msg.sender, publication), "Cannot propose");
    ///     super.propose(publication);
    /// }
    /// ```
    function propose(bytes memory publication) external virtual {
        bytes32 checkpoint = toCheckpoint(publication);
        // TODO: Is it really convenient to send the publication to another contract? e.g. PublicationFeed
        _propose(checkpoint, publication);
    }

    /// @inheritdoc IRollup
    function sendSignal(bytes32 value) public returns (bytes32) {
        bytes32 slot = value.signal();
        emit SignalSent(value);
        return slot;
    }

    /// @notice Internal version of {propose} that receives a checkpoint.
    function _propose(bytes32 checkpoint, bytes memory publication) internal virtual {
        checkpoint.signal();
        emit Proposed(checkpoint, publication);
    }

    /// @dev See {IRollup-prove}.
    ///
    /// Consider restricting the right to prove a transition by overriding this function.
    function prove(bytes32 from, bytes32 target, bytes memory proof) external virtual {
        require(isValidTransition(from, target, proof), InvalidProof());
        require(proposed(target), UnknownCheckpoint());
        require(!proven(from), ProvenCheckpoint());

        toProvenSignal(target).signal();
        _latestCheckpoint = target;
        emit Proven(target);
    }
}
