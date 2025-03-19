// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IPublicationFeed} from "../interfaces/IPublicationFeed.sol";

import {LibBiddedPeriod} from "../../libs/LibBiddedPeriod.sol";
import {NativeVault} from "./NativeVault.sol";

/// @dev Extension of {L1Rollup} that implements an Ahead of Time (AOT) Auction for proving markets.
///
/// Smart Contracts systems that defer the proof generation of a state transition to a later time (e.g. L2s),
/// require a mechanism to incentivize generating and submitting these proofs. This is necessary to ensure the
/// chain's liveness (i.e. the chain finalizes blocks in a timely manner).
///
/// This contract proposes a design for a proving market that incentivizes the generation of proofs for state
/// transitions by letting provers to bid for a _period_ in which they can post proofs. Proposers can bid for the
/// next period, and the lowest bid wins. The winning prover can then post proofs for state transitions within the
/// period, ending after a `exitDelay` following either
///
/// a) a call to `exit` by the prover, or
/// b) a call to `evictProver` after `provingDeadline` has passed.
contract L1RollupProvingAuction is NativeVault {
    using LibBiddedPeriod for LibBiddedPeriod.BiddedPeriod;

    event ProverOffer(address indexed proposer, uint256 periodStart, uint256 fee);
    event ProverEvicted(address indexed prover, address indexed evictor, uint256 periodEnd);
    event ProverExited(address indexed prover, uint256 periodEnd);
    event NewPeriod(uint256 period);

    error OnlyProver();
    error InsufficientUndercut();
    error PeriodEnded();
    error RecentPublication();

    LibBiddedPeriod.BiddedPeriod[] private _periods;
    mapping(bytes32 commitment => uint256) private _proposedAt;

    /// @notice Current proving period. Defines who can post proofs.
    function currentPeriodId() public view virtual returns (uint256) {
        return _periods.length - 1;
    }

    function currentPeriod() public view virtual returns (LibBiddedPeriod.BiddedPeriod memory) {
        return _periods[currentPeriodId()];
    }

    /// @notice Returns the minimum liveness bond required to bid
    function minLivenessBond() public view virtual returns (uint256) {
        return 0.1 ether; // TODO: set a reasonable value?
    }

    /// @notice Returns the minimum outbid percentage required to bid for a period not yet ended
    function minUndercutPercentage() public view virtual returns (uint256) {
        return 5; // 5%
    }

    /// @notice Amount in seconds for the prover to post a proof after the period has started.
    function provingDeadline() public view virtual returns (uint48) {
        return 10 minutes; // TODO: set a reasonable value?
    }

    /// @notice Amount in seconds for the bidded period to start, once bid.
    function successionDelay() public view virtual returns (uint48) {
        return 1 minutes; // TODO: set a reasonable value?
    }

    /// @notice Amount in seconds for the prover to fully exit the period after calling `exit`.
    function exitDelay() public view virtual returns (uint48) {
        return 1 minutes; // TODO: set a reasonable value?
    }

    /// @notice Maximum amount of seconds the chain can be inactive before the prover can be evicted.
    function livenessWindow() public view virtual returns (uint48) {
        return 1 days; // TODO: set a reasonable value?
    }

    function evictionSlashingPercentage() public view virtual returns (uint256) {
        return 10_000; // 10% in bps
    }

    /// @dev Calculates the percentage of the `amount` that is slashab
    function feeEvictionSlashingPercentage(uint256 amount) public view virtual returns (uint256) {
        uint256 bp = evictionSlashingPercentage(amount, bps);
        require((amount * bps) >= 10_000);
        return (amount * bps) / 10_000;
    }

    function propose(bytes memory publication) external virtual override {
        // Hook the creation of a new period in case the current one has ended
        uint256 currentPeriod = currentPeriodId();

        if (_periods[currentPeriod].hasEnded()) {
            // Create a new period by increasing the length of the periods array
            nextPeriod = ++currentPeriod;
            assembly ("memory-safe") {
                sstore(_periods.slot, nextPeriod)
            }
            emit NewPeriod(nextPeriod);
        }

        // Pay the publication fee. Requires calling `deposit` first.
        _payPublicationFee(msg.sender);

        super.propose(publication);
    }

    function _propose(bytes32 commitment) internal virtual override {
        _proposedAt[commitment] = block.timestamp;
        super._propose(commitment);
    }

    /// @dev Prove a state transition for an open period. Restricted to the current prover.
    function prove(bytes32 from, bytes32 target, bytes memory proof) external virtual {
        require(msg.sender == _periods[currentPeriodId()].prover, OnlyProver());
        super.prove(from, target, proof);
    }

    function _payPublicationFee(address proposer) internal virtual {
        uint256 requiredFee = _periods[currentPeriod].fee;

        // Deduct fee from proposer's balance and add to accumulated fees
        _reduceBalance(proposer, requiredFee);
        _periods[currentPeriod].accumulatedFees += requiredFee;
    }

    function bid(uint256 offeredFee) external {
        uint256 _currentPeriodId = currentPeriodId();
        LibBiddedPeriod.BiddedPeriod storage _currentPeriod = _periods[_currentPeriodId];
        LibBiddedPeriod.BiddedPeriod storage nextPeriod =
            _commitLivenessBondForNextPeriod(_periods[_currentPeriodId + 1], msg.sender);
        uint256 requiredMaxFee;

        if (_currentPeriod.isActive()) {
            // If the period is still active the bid has to be lower
            _validateOfferedFee(_currentPeriod, offeredFee);
            _currentPeriod.scheduleStartAfterDelayWithDeadline(successionDelay(), provingDeadline());
        } else if (nextPeriod.isBidded()) {
            // If there's already a bid for the next period the bid has to be lower
            _validateOfferedFee(nextPeriod, offeredFee);
            // Refund the liveness bond to the losing bid
            _increaseBalance(nextPeriod.prover, nextPeriod.stake);
        }

        // Record the next period info
        nextPeriod.prover = msg.sender;
        nextPeriod.fee = offeredFee;

        emit ProverOffer(msg.sender, _currentPeriodId + 1, offeredFee);
    }

    function _validateOfferedFee(LibBiddedPeriod.BiddedPeriod storage period, uint256 offeredFee)
        internal
        view
        override
        returns (uint256)
    {
        uint256 currentFee = period.fee;
        uint256 requiredMaxFee = currentFee - calculatePercentage(currentFee, minUndercutPercentage());
        require(offeredFee <= requiredMaxFee, InsufficientUndercut());
    }

    function exit() external {
        LibBiddedPeriod.BiddedPeriod storage period = _periods[currentPeriodId()];
        address _prover = period.prover;
        require(msg.sender == _prover, OnlyProver());
        require(!period.isEnded(), PeriodEnded());

        emit ProverExited(_prover, period.scheduleEndAfterDelayWithDeadline(exitDelay(), provingDeadline()));
    }

    function evictProver(uint256 publicationId, bytes memory publication) external {
        bytes32 commitment = toCommitment(publication);
        require(_proposedAt[commitment] + livenessWindow() < block.timestamp, RecentPublication());

        // Reward the evictor and slash the prover
        uint256 evictorIncentive = feeEvictionSlashingPercentage(period.stake);
        balances[msg.sender] += evictorIncentive;
        period.stake -= evictorIncentive;

        emit ProverEvicted(period.prover, msg.sender, period.scheduleEndAfterDelayWithDeadline(exitDelay(), 0));
    }

    /// @dev Commits the liveness bond for the next period from the prover's balance.
    function _commitLivenessBondForNextPeriod(LibBiddedPeriod.BiddedPeriod storage nextPeriod, address prover)
        internal
        returns (Period storage)
    {
        uint256 livenessBond = minLivenessBond();
        require(balances(prover) >= livenessBond, InsufficientBalance());
        _reduceBalance(address(this), livenessBond);
        nextPeriod.stake = livenessBond;
    }
}
