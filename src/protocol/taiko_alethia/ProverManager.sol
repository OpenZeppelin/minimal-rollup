// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "../ICheckpointTracker.sol";
import {IProposerFees} from "../IProposerFees.sol";
import {IProverManager} from "../IProverManager.sol";
import {IPublicationFeed} from "../IPublicationFeed.sol";

abstract contract ProverManager is IProposerFees, IProverManager {
    // TODO: Optimize storage by packing the struct. Things like `fee` and `delayedFeePercentage` should be packed
    // together.
    struct Period {
        address prover;
        uint256 stake; // stake the prover locked to register
        uint256 fee; // per-publication fee (in wei)
        uint16 delayedFeePercentage; // the percentage (in bps) of the fee that is charged for delayed publications.
        uint256 end; // the end of the period(this may happen because the prover exits, is evicted or outbid)
        uint256 deadline; // the time by which the prover needs to submit a proof
        bool pastDeadline; // whether the proof came after the deadline
    }

    address public immutable inbox;
    ICheckpointTracker public immutable checkpointTracker;
    IPublicationFeed public immutable publicationFeed;

    /// @notice Common balances for proposers and provers
    mapping(address user => uint256 balance) public balances;
    /// @notice The current period
    uint256 public currentPeriodId;
    /// @dev Periods represent proving windows
    mapping(uint256 periodId => Period) private _periods;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event ProverOffer(address indexed proposer, uint256 period, uint256 fee, uint256 stake);
    event ProverEvicted(address indexed prover, address indexed evictor, uint256 periodEnd, uint256 livenessBond);
    event ProverExited(address indexed prover, uint256 periodEnd, uint256 provingDeadline);
    event NewPeriod(uint256 period);

    constructor(
        address _inbox,
        address _checkpointTracker,
        address _publicationFeed,
        address _initialProver,
        uint256 _initialFee
    ) payable {
        inbox = _inbox;
        checkpointTracker = ICheckpointTracker(_checkpointTracker);
        publicationFeed = IPublicationFeed(_publicationFeed);

        // Close the first period so every period has a previous one (and an implicit start timestamp)
        // The initial fee and prover will take effect in the block after this one
        _deposit(_initialProver, msg.value);
        _claimProvingVacancy(_initialFee, _initialProver);
    }

    /// @notice Deposit ETH into the contract. The deposit can be used both for opting in as a prover or proposer
    function deposit() external payable {
        _deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw available(unlocked) funds.
    /// @param amount The amount to withdraw
    function withdraw(uint256 amount) external {
        balances[msg.sender] -= amount;

        address to = msg.sender;
        bool ok;
        // Using assembly to avoid memory allocation costs; only the call's success matters to ensure funds are sent.
        assembly ("memory-safe") {
            ok := call(gas(), to, amount, 0, 0, 0, 0)
        }
        require(ok, "Withdraw failed");

        emit Withdrawal(msg.sender, amount);
    }

    /// @inheritdoc IProposerFees
    /// @dev This function advances to the next period if the current period has ended.
    function payPublicationFee(address proposer, bool isDelayed) external {
        require(msg.sender == inbox, "Only the Inbox contract can call this function");

        uint256 periodId = currentPeriodId;

        uint256 periodEnd = _periods[periodId].end;
        if (periodEnd != 0 && block.timestamp > periodEnd) {
            // Advance to the next period
            currentPeriodId = ++periodId;
            emit NewPeriod(periodId);
        }

        // Deduct fee from proposer's balance
        uint256 fee = _periods[periodId].fee;
        if (isDelayed) {
            // If it is a new period, we already have the value of the delayed fee percentage. The compiler should
            // usually be able to optimize this, but to make sure we do it explicitly.
            fee = _calculatePercentage(fee, _periods[periodId].delayedFeePercentage);
        }
        balances[proposer] -= fee;
    }

    /// @inheritdoc IProverManager
    /// @dev The offered fee has to be at most `maxBidPercentage` of the current best price.
    /// @dev The current best price may be the current prover's fee or the fee of the next bid, depending on whether the
    /// period is active or not.
    /// An active period is one that doesn't have an `end` timestamp yet.
    function bid(uint256 offeredFee) external {
        uint256 currentPeriodId_ = currentPeriodId;
        Period storage currentPeriod = _periods[currentPeriodId_];
        Period storage nextPeriod = _periods[currentPeriodId_ + 1];
        if (currentPeriod.end == 0) {
            _ensureSufficientUnderbid(currentPeriod.fee, offeredFee);
            _closePeriod(currentPeriod, _successionDelay(), _provingWindow());
        } else {
            address nextProverAddress = nextPeriod.prover;
            if (nextProverAddress != address(0)) {
                _ensureSufficientUnderbid(nextPeriod.fee, offeredFee);

                // Refund the liveness bond to the losing bid
                balances[nextProverAddress] += nextPeriod.stake;
            }
        }

        // Record the next period info
        uint256 livenessBond_ = _livenessBond();
        _updatePeriod(nextPeriod, msg.sender, offeredFee, livenessBond_);

        emit ProverOffer(msg.sender, currentPeriodId_ + 1, offeredFee, livenessBond_);
    }

    /// @inheritdoc IProverManager
    /// @dev This can be called by anyone, and they get `evictorIncentivePercentage` of the liveness bond as an
    /// incentive.
    function evictProver(IPublicationFeed.PublicationHeader calldata publicationHeader) external {
        require(publicationFeed.validateHeader(publicationHeader), "Invalid publication");

        uint256 publicationTimestamp = publicationHeader.timestamp;
        require(publicationTimestamp + _livenessWindow() < block.timestamp, "Publication is not old enough");

        Period storage period = _periods[currentPeriodId];
        require(period.end == 0, "Proving period is not active");

        ICheckpointTracker.Checkpoint memory lastProven = checkpointTracker.getProvenCheckpoint();
        require(publicationHeader.id > lastProven.publicationId, "Publication has been proven");

        // We use this to mark the prover as evicted
        (uint256 end,) = _closePeriod(period, _exitDelay(), 0);

        // Reward the evictor and slash the prover
        uint256 evictorIncentive = _calculatePercentage(period.stake, _evictorIncentivePercentage());
        balances[msg.sender] += evictorIncentive;
        period.stake -= evictorIncentive;

        emit ProverEvicted(period.prover, msg.sender, end, period.stake);
    }

    /// @inheritdoc IProverManager
    /// @dev The prover still has to wait for the `exitDelay` to allow other provers to bid for the role.
    /// @dev The liveness bond can only be withdrawn once the period has been fully proven.
    function exit() external {
        Period storage period = _periods[currentPeriodId];
        address prover = period.prover;
        require(msg.sender == prover, "Not current prover");
        require(period.end == 0, "Prover already exited");

        (uint256 end, uint256 deadline) = _closePeriod(period, _exitDelay(), _provingWindow());
        emit ProverExited(prover, end, deadline);
    }

    /// @inheritdoc IProverManager
    function claimProvingVacancy(uint256 fee) external {
        _claimProvingVacancy(fee, msg.sender);
    }

    /// @inheritdoc IProverManager
    function prove(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader calldata firstPub,
        IPublicationFeed.PublicationHeader calldata lastPub,
        uint256 numPublications,
        uint256 numDelayedPublications,
        bytes calldata proof,
        uint256 periodId
    ) external {
        Period storage period = _periods[periodId];
        uint256 previousPeriodEnd = periodId > 0 ? _periods[periodId - 1].end : 0;

        require(publicationFeed.validateHeader(lastPub), "Last publication does not exist");
        require(end.publicationId == lastPub.id, "Last publication does not match end checkpoint");
        require(period.end == 0 || lastPub.timestamp <= period.end, "Last publication is after the period");

        require(publicationFeed.validateHeader(firstPub), "First publication does not exist");
        require(start.publicationId + 1 == firstPub.id, "First publication not immediately after start checkpoint");
        require(firstPub.timestamp > previousPeriodEnd, "First publication is before the period");

        checkpointTracker.proveTransition(start, end, numPublications, numDelayedPublications, proof);

        bool isPastDeadline = block.timestamp > period.deadline && period.deadline != 0;
        if (isPastDeadline) {
            // Whoever proves the final publication in this period can (eventually) call `finalizePastPeriod` to claim a
            // percentage of the stake. In practice, a single prover will likely close the whole period with one proof.
            period.prover = msg.sender;
            period.pastDeadline = true;
        }
        uint256 baseFee = period.fee;
        uint256 regularPubFee = (numPublications - numDelayedPublications) * baseFee;

        uint256 delayedPubFee;

        if (numDelayedPublications > 0) {
            uint256 delayedFee = _calculatePercentage(baseFee, period.delayedFeePercentage);
            delayedPubFee = numDelayedPublications * delayedFee;
        }

        balances[period.prover] += regularPubFee + delayedPubFee;
    }

    /// @inheritdoc IProverManager
    function finalizePastPeriod(uint256 periodId, IPublicationFeed.PublicationHeader calldata provenPublication)
        external
    {
        ICheckpointTracker.Checkpoint memory lastProven = checkpointTracker.getProvenCheckpoint();
        require(publicationFeed.validateHeader(provenPublication), "Invalid publication header");
        require(lastProven.publicationId >= provenPublication.id, "Publication must be proven");

        Period storage period = _periods[periodId];
        require(provenPublication.timestamp > period.end, "Publication must be after period");

        uint256 stake = period.stake;
        balances[period.prover] += period.pastDeadline ? _calculatePercentage(stake, _rewardPercentage()) : stake;
        period.stake = 0;
    }

    /// @inheritdoc IProposerFees
    function getCurrentFees() external view returns (uint256 fee, uint256 delayedFee) {
        uint256 currentPeriod = currentPeriodId;
        uint256 periodEnd = _periods[currentPeriod].end;
        if (periodEnd != 0 && block.timestamp > periodEnd) {
            currentPeriod++;
        }

        Period storage period = _periods[currentPeriod];
        fee = period.fee;
        delayedFee = _calculatePercentage(fee, period.delayedFeePercentage);
    }

    /// @notice Returns the period for a given period id
    /// @param periodId The id of the period
    /// @return _ The period
    function getPeriod(uint256 periodId) external view returns (Period memory) {
        return _periods[periodId];
    }

    /// @dev Ensure the offered fee is low enough. It must be at most `maxBidPercentage` of the fee it is outbidding
    /// @param fee The fee to be outbid (either the current period's fee or next period's winning fee)
    /// @param offeredFee The new bid
    function _ensureSufficientUnderbid(uint256 fee, uint256 offeredFee) internal view virtual {
        uint256 requiredMaxFee = _calculatePercentage(fee, _maxBidPercentage());
        require(offeredFee <= requiredMaxFee, "Offered fee not low enough");
    }

    /// @dev Returns the maximum percentage (in bps) of the previous bid a prover can offer and still have a successful
    /// bid
    /// @return _ The maximum bid percentage value
    function _maxBidPercentage() internal view virtual returns (uint256);

    /// @dev Returns the time window after which a publication is considered old enough for prover eviction
    /// @return _ The liveness window value in seconds
    function _livenessWindow() internal view virtual returns (uint256);

    /// @dev Returns the time delay before a new prover takes over after a successful bid
    /// @return _ The succession delay value in seconds
    function _successionDelay() internal view virtual returns (uint256);

    /// @dev Returns the delay after which the current prover can exit, or is removed if evicted
    /// @return _ The exit delay value in seconds
    function _exitDelay() internal view virtual returns (uint256);

    /// @dev Returns the time window for a prover to submit a valid proof after their period ends
    /// @return _ The proving window value in seconds
    function _provingWindow() internal view virtual returns (uint256);

    /// @dev Returns the minimum stake required to be a prover
    /// @return _ The liveness bond value in wei
    function _livenessBond() internal view virtual returns (uint256);

    /// @dev Returns the percentage (in bps) of the liveness bond that the evictor gets as an incentive
    /// @return _ The evictor incentive percentage
    function _evictorIncentivePercentage() internal view virtual returns (uint256);

    /// @dev Returns the percentage (in bps) of the remaining liveness bond rewarded to the prover
    /// @return _ The reward percentage
    function _rewardPercentage() internal view virtual returns (uint256);

    /// @dev The percentage (in bps) of the fee that is charged for delayed publications
    /// @dev It is recommended to set this to >10,000 bps since delayed publications should usually be charged at a
    /// higher rate
    function _delayedFeePercentage() internal view virtual returns (uint16);

    /// @dev Increases `user`'s balance by `amount`
    function _deposit(address user, uint256 amount) private {
        balances[user] += amount;
        emit Deposit(user, amount);
    }

    /// @dev implementation of IProverManager.claimProvingVacancy with the option to specify a prover
    /// This lets the constructor claim the first vacancy on behalf of _initialProver
    function _claimProvingVacancy(uint256 fee, address prover) private {
        uint256 periodId = currentPeriodId;
        Period storage period = _periods[periodId];
        require(period.prover == address(0) && period.end == 0, "No proving vacancy");
        _closePeriod(period, 0, 0);

        Period storage nextPeriod = _periods[periodId + 1];
        _updatePeriod(nextPeriod, prover, fee, _livenessBond());
    }

    /// @dev Calculates the percentage of a given numerator scaling up to avoid precision loss
    /// @param amount The number to calculate the percentage of
    /// @param bps The percentage expressed in basis points(https://muens.io/solidity-percentages)
    /// @return _ The calculated percentage of the given numerator
    function _calculatePercentage(uint256 amount, uint256 bps) private pure returns (uint256) {
        return (amount * bps) / 10_000;
    }

    /// @dev Updates a period with prover information and transfers the liveness bond
    /// @param period The period to update
    /// @param prover The address of the prover
    /// @param fee The fee offered by the prover
    /// @param stake The liveness bond to be staked
    function _updatePeriod(Period storage period, address prover, uint256 fee, uint256 stake) private {
        period.prover = prover;
        period.fee = fee;
        period.delayedFeePercentage = _delayedFeePercentage();
        period.stake = stake; // overwrite previous value. We assume the previous value is zero or already returned
        balances[prover] -= stake;
    }

    /// @dev Sets a period's end and deadline timestamps
    /// @param period The period to finalize
    /// @param endDelay The duration (from now) when the period will end
    /// @param provingWindow_ The duration that proofs can be submitted after the end of the period
    /// @return end The period's end timestamp
    /// @return deadline The period's deadline timestamp
    function _closePeriod(Period storage period, uint256 endDelay, uint256 provingWindow_)
        private
        returns (uint256 end, uint256 deadline)
    {
        end = block.timestamp + endDelay;
        deadline = end + provingWindow_;
        period.end = end;
        period.deadline = deadline;
    }
}
