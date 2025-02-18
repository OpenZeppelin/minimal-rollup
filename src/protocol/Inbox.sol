// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";

import {IBondManager} from "./IBondManager.sol";
import {IPreconfTaskManager} from "./IPreconfTaskManager.sol";
import {IVerifier} from "./IVerifier.sol";

contract Inbox {
    /// @dev A struct to store the checkpoint and who proposed it
    struct Checkpoint {
        bytes32 checkpoint;
        address proposer;
    }

    // TODO: Optimize using the ring buffer design if we don't need to store all checkpoints
    // Checkpoints can be anything that describes the state of the rollup at a given publication (the most common case
    // is the state root)
    /// @dev tracks proven checkpoints after applying the publication at `_dataFeed.getPublicationHash(pubIdx)`

    mapping(uint256 pubIdx => Checkpoint checkpoint) checkpoints;

    /// @dev the highest `pubIdx` in `checkpoints`
    uint256 lastProvenIdx;

    IDataFeed immutable _dataFeed;
    // This would usually be retrieved dynamically as in the current Taiko implementation, but for simplicity we are
    // just setting it in the constructor
    IVerifier immutable _verifier;

    IPreconfTaskManager immutable _preconfer;

    IBondManager immutable _bondManager;

    /// @notice Emitted when a checkpoint is proposed
    /// @param pubIdx The publication index at which the checkpoint was proposed
    /// @param proposer The address that proposed the checkpoint
    /// @param checkpoint The state root (or other) checkpoint
    event CheckpointProposed(uint256 indexed pubIdx, address indexed proposer, bytes32 checkpoint);

    /// @notice Emitted when a checkpoint is proven
    /// @param pubIdx The index of the publication at which the checkpoint was proven
    /// @param checkpoint The checkpoint that was proven
    event CheckpointProven(uint256 indexed pubIdx, bytes32 checkpoint);

    /**
     * @param genesis The checkpoint describing the initial state of the rollup
     * @param dataFeed The input data source that updates the state of this rollup
     * @param verifier A contract that can verify the validity of a transition from one checkpoint to another
     * @param preconfTaskManager The preconf task manager that decides who can propose at a given slot
     * @param bondManager The contract that manages all bonding logic to incentivize proving
     */
    constructor(bytes32 genesis, address dataFeed, address verifier, address preconfTaskManager, address bondManager) {
        require(genesis != 0, "Invalid genesis checkpoint");

        // set the genesis checkpoint of the rollup - genesis is trusted to be correct
        checkpoints[0] = genesis;

        _dataFeed = IDataFeed(dataFeed);
        _verifier = IVerifier(verifier);
        _preconfer = IPreconfTaskManager(preconfTaskManager);
        _bondManager = IBondManager(bondManager);
    }

    /**
     * @notice Proposes a checkpoint for a given publication, which needs to be proven at a later time.
     * @dev Restricted to the current preconfer, who has monopoly rights over L2 block production
     *      during certain slots. The bond is debited from the proposer.
     * @param publicationIdx The publication index for which the checkpoint is proposed
     * @param newCheckpoint The checkpoint describing the state after applying that publication
     */
    function proposeCheckpoint(uint256 publicationIdx, bytes32 newCheckpoint) external {
        // Check that the publication exists
        require(_dataFeed.getPublicationHash(publicationIdx) != 0, "Publication does not exist");

        // Only the current preconfer can propose the next checkpoint. If it is the address zero, it means proposing is
        // permissionless
        address currentPreconfer = _preconfer.getPreconfer(block.timestamp);
        if (currentPreconfer != address(0)) {
            require(msg.sender == currentPreconfer, "Not the current preconfer");
        }

        // Debit the bond from the proposer using the bond manager
        uint256 bondAmount = _bondManager.calculateLivenessBond(msg.sender, publicationIdx);
        _bondManager.debitBond(msg.sender, bondAmount);

        // Store the checkpoint and remember who proposed it
        checkpoints[publicationIdx] = Checkpoint({checkpoint: newCheckpoint, proposer: msg.sender});

        emit CheckpointProposed(publicationIdx, msg.sender, newCheckpoint);
    }

    /// @notice Proves the transition between two checkpoints
    /// @dev Updates the `lastProvenIdx` to `end` on success and credits the bond according to the `BondManager` logic
    /// @param end The index of the last publication in this transition
    /// @param endCheckpoint The claimed checkpoint at the end of this transition
    /// @param proof Arbitrary data passed to the verifier contract to confirm the transition validity
    function proveBetween(uint256 end, bytes32 endCheckpoint, bytes calldata proof) external {
        require(end > lastProvenIdx, "Publication already proven");

        // If we assume consecutive proving, then the start is always the last proven index
        Checkpoint base = checkpoints[lastProvenIdx];

        // Ensure the designated prover (auction winner, proposer, etc.) is the one proving.
        // If `designatedProver` is the address zero, it means proving is permissionless
        address designatedProver = _bondManager.getDesignatedProver(end);
        if (designatedProver != address(0)) {
            require(msg.sender == designatedProver, "Caller is not the designated prover");
        }

        _verifier.verifyProof(
            _dataFeed.getPublicationHash(lastProvenIdx),
            _dataFeed.getPublicationHash(end),
            base.checkpoint,
            endCheckpoint,
            proof
        );

        lastProvenIdx = end;

        // Credit the bond to the prover or proposer(s) according to the `BondManager` logic
        // TODO: we should actually have a list of proposers.
        // TODO: how and who determines the amount?
        _bondManager.creditBond(msg.sender, base.proposer, bondAmount, true);

        emit CheckpointProven(end, endCheckpoint);
    }
}
