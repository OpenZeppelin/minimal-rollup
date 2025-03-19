// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IProverManager} from "./IProverManager.sol";

/// @dev Interface for an L1 Rollup.
///
/// A rollup is defined by a sequence of cryptographic commitments produced from publications
/// that define the progression of the chain.
///
/// Publications are proposed with `propose` and converted into a commitment depending on
/// the proof system with `toCommitment` (e.g. a hash for sgx or zk-proofs). Later, the commitment
/// is proven off-chain and posted to the contract with `transition`.
///
/// For convenience, the interface enforces a signalling mechanism that can be used to log values
/// to entities monitoring this rollup. This way, applications can call `sendSignal` to store
/// a value and then incentivize the proposer to facilitate it on the L2.
///
/// For example, values emitted through the `SignalSent` event can be "fast-tracked" to the L2,
/// enabling [same-slot L1 -> L2 message passing](https://ethresear.ch/t/same-slot-l1-l2-message-passing/21186).
interface IL1Rollup {
    event Proposed(bytes32 indexed commitment, bytes publication);
    event Proven(bytes32 indexed commitment);

    event SignalSent(bytes32 indexed value);

    error InvalidProof();
    error UnknownCommitment();
    error ProvenCommitment();

    /// @notice Last proven commitment. Defines the current state of the chain.
    function latestCommitment() external view returns (bytes32);

    /// @notice Returns the proven commitment that follows `commitment`.
    function nextCommitment(bytes32 commitment) external view returns (bytes32);

    /// @notice Returns whether the `publication` has been proposed.
    function proposed(bytes calldata publication) external view returns (bool);

    /// @notice Returns whether the `publication` has been proven.
    function proven(bytes calldata publication) external view returns (bool);

    /// @notice Returns whether the signal for the `commitment` has been sent. Emits {SignalSent} when called.
    function signalSent(bytes32 value) external view returns (bool);

    /// @notice Returns whether the `proof` was verified correctly to transitioning between `from` and `target`
    /// commitments.
    function isValidTransition(bytes32 from, bytes32 target, bytes memory proof) external view returns (bool);

    /// @notice Converts a publication into a cryptographic commitment (e.g. a hash).
    function toCommitment(bytes memory publication) external view returns (bytes32);

    /// @notice Proposes a new publication to the chain. Relies on {toCommitment} to process the publication
    /// into a commitment. Emits a {Proposed} event.
    function propose(bytes memory publication) external;

    /// @notice Updates `provenCommitment` to `target` after verifying the proof for a transition between `from` and
    /// `target` commitments. Emits {Proven} if the proof can be verified (see {isValidTransition}).
    /// Otherwise, reverts with {InvalidProof}.
    function prove(bytes32 from, bytes32 target, bytes memory proof) external;

    /// @dev Stores a data signal and returns its storage location.
    function sendSignal(bytes32 value) external returns (bytes32);
}
