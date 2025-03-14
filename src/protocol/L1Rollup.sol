// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IL1Rollup} from "./interfaces/IL1Rollup.sol";

import {LibSignal} from "../libs/LibSignal.sol";

/// @dev Implementation of {IL1Rollup}.
///
/// An implementation of the {isValidTransition} and the {toCommitment} functions must be provided by a derived
/// contract, which define the proving scheme and how to produce a commitment from a publication.
///
/// The commitments are also signalled when proposed, allowing to provide them on the L2 in the same-slot as
/// the publication by monitoring the {IL1Rollup-Proposed} event. To avoid duplicated events, the {SignalSent}
/// event is skipped when calling `propose`.
///
/// A production-ready implementation should consider the following:
///
/// - Incentivize provers to compute off-chain proofs and post them to the contract.
/// - Restrict the right to propose a publication.
///
/// Naturally, both can develop independent markets. One as an auction for provers to bid for a period to post proofs,
/// and the other as a market for proposers to bid for the right to propose a publication (allowing them to extract
/// MEV).
abstract contract L1Rollup is IL1Rollup {
    using LibSignal for bytes32;

    mapping(bytes32 commitment => bytes32) private _nextCommitment;
    mapping(bytes commitment => bool) private _proven;
    bytes32 private _latestCommitment;

    /// @dev Initializes the rollup with a genesis commitment describing the initial state of the rollup.
    constructor(bytes32 genesisCommitment) {
        _latestCommitment = genesisCommitment;
    }

    /// @inheritdoc IL1Rollup
    function latestCommitment() public view virtual returns (bytes32) {
        return _latestCommitment;
    }

    /// @inheritdoc IL1Rollup
    function nextCommitment(bytes32 from) public view virtual returns (bytes32) {
        return _nextCommitment[from];
    }

    /// @inheritdoc IL1Rollup
    function proposed(bytes calldata publication) external view override returns (bool) {
        return signalSent(toCommitment(publication));
    }

    /// @inheritdoc IL1Rollup
    function proven(bytes calldata publication) external view returns (bool) {
        return _proven[toCommitment(publication)];
    }

    /// @inheritdoc IL1Rollup
    function signalSent(bytes32 value) public view returns (bool) {
        return value.signaled();
    }

    /// @inheritdoc IL1Rollup
    function sendSignal(bytes32 value) public returns (bytes32) {
        bytes32 slot = value.signal();
        emit SignalSent(value);
        return slot;
    }

    /// @inheritdoc IL1Rollup
    function isValidTransition(bytes32 from, bytes32 target, bytes memory proof) public view virtual returns (bool);

    /// @inheritdoc IL1Rollup
    function toCommitment(bytes memory publication) public view virtual returns (bytes32);

    /// @inheritdoc IL1Rollup
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
        bytes32 commitment = toCommitment(publication);
        _propose(commitment);
    }

    /// @notice Internal version of {propose} that receives a commitment.
    function _propose(bytes32 commitment) internal {
        commitment.signal();
        emit Proposed(commitment, publication);
    }

    /// @inheritdoc IL1Rollup
    function prove(bytes32 from, bytes32 target, bytes memory proof) external virtual {
        require(isValidTransition(from, target, proof), InvalidProof());
        require(proposed(target), UnknownCommitment());
        require(proven(from), UnprovenCommitment());

        _proven[toCommitment(publication)] = true;
        _latestCommitment = target;
        emit Proven(target);
    }

    /// @notice The maximum number of additional checkpoint transitions to apply in a single proof
    /// @dev This limits the overhead required to submit a proof
    function _maxExtraUpdates() internal pure virtual returns (uint256) {
        return 10; // TODO: What is a reasonable number here?
    }

    function _findLastProvenCommitment(bytes32 from) private view returns (bytes32) {
        bytes32 nextCommitment = nextCommitment(from);
        uint256 i;
        while (nextCommitment != 0 && _maxExtraUpdates() <= ++i) {
            from = nextCommitment;
            nextCommitment = nextCommitment(from);
        }
        return from;
    }
}
