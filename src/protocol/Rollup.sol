// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IRollup} from "./interfaces/IRollup.sol";

import {LibSignal} from "../libs/LibSignal.sol";

/// @dev Implementation of {IRollup}.
///
/// An implementation of the {isValidTransition} and the {toCheckpoint} functions must be provided by a derived
/// contract, which define the proving scheme and how to produce a checkpoint from a publication.
///
/// The checkpoints are also signalled when proposed, allowing to provide them on the L2 in the same-slot as
/// the publication by monitoring the {IRollup-Proposed} event. To avoid duplicated events, the {SignalSent}
/// event is skipped when calling `propose`.
///
/// A production-ready implementation should consider the following:
///
/// - Incentivize provers to compute off-chain proofs and post them to the contract.
/// - Restrict the right to propose a publication.
///
/// Naturally, both can develop independent markets. One as an auction for provers to bid for a period to post proofs,
/// and the other as a market for proposers to bid for the right to propose a publication (allowing them to extract
/// MEV or issue preconfirmations).
abstract contract Rollup is IRollup {
    using LibSignal for bytes32;

    mapping(bytes checkpoint => bool) private _proven;
    bytes32 private _latestCheckpoint;

    /// @dev Initializes the rollup with a genesis checkpoint describing the initial state of the rollup.
    constructor(bytes32 genesisCheckpoint) {
        _latestCheckpoint = genesisCheckpoint;
    }

    /// @inheritdoc IRollup
    function latestCheckpoint() public view virtual returns (bytes32) {
        return _latestCheckpoint;
    }

    /// @inheritdoc IRollup
    function proposed(bytes calldata publication) external view override returns (bool) {
        return signalSent(toCheckpoint(publication));
    }

    /// @inheritdoc IRollup
    function proven(bytes calldata publication) external view returns (bool) {
        return _proven[toCheckpoint(publication)];
    }

    /// @inheritdoc IRollup
    function signalSent(bytes32 value) public view returns (bool) {
        return value.signaled();
    }

    /// @inheritdoc IRollup
    function isValidTransition(bytes32 from, bytes32 target, bytes memory proof) public view virtual returns (bool);

    /// @inheritdoc IRollup
    function toCheckpoint(bytes memory publication) public view virtual returns (bytes32);

    /// @inheritdoc IRollup
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
        _propose(checkpoint);
    }

    /// @inheritdoc IRollup
    function sendSignal(bytes32 value) public returns (bytes32) {
        bytes32 slot = value.signal();
        emit SignalSent(value);
        return slot;
    }

    /// @notice Internal version of {propose} that receives a checkpoint.
    function _propose(bytes32 checkpoint) internal virtual {
        checkpoint.signal();
        emit Proposed(checkpoint, publication);
    }

    /// @inheritdoc IRollup
    ///
    /// Consider restricting the right to prove a transition by overriding this function.
    function prove(bytes32 from, bytes32 target, bytes memory proof) external virtual {
        require(isValidTransition(from, target, proof), InvalidProof());
        require(proposed(target), UnknownCheckpoint());
        require(!proven(from), ProvenCheckpoint());

        _proven[toCheckpoint(publication)] = true;
        _latestCheckpoint = target;
        emit Proven(target);
    }
}
