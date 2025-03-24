// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "../ICheckpointTracker.sol";
import {IProposerFees} from "../IProposerFees.sol";
import {IProverManager} from "../IProverManager.sol";
import {IPublicationFeed} from "../IPublicationFeed.sol";

contract ProverManager is IProposerFees, IProverManager {
    struct Period {
        address prover;
        uint256 stake; // stake the prover locked to register
        uint256 fee; // per-publication fee (in wei)
        uint256 end; // the end of the period(this may happen because the prover exits, is evicted or outbid)
        uint256 deadline; // the time by which the prover needs to submit a proof
        bool pastDeadline; // whether the proof came after the deadline, we set this to true when burning the stake of
            // the original prover
    }

    /// @dev This struct is necessary to pass it to the constructor and avoid stack too deep errors
    /// When some values in the contract stop being immutable, we may change this to be more efficient
    struct ProverManagerConfig {
        uint256 maxBidPercentage;
        uint256 livenessWindow;
        uint256 successionDelay;
        uint256 exitDelay;
        uint256 provingWindow;
        uint256 livenessBond;
        uint256 evictorIncentivePercentage;
        uint256 burnedStakePercentage;
    }

    address public immutable inbox;
    ICheckpointTracker public immutable checkpointTracker;
    IPublicationFeed public immutable publicationFeed;

    // -- Configuration parameters --
    /// @notice The maximum percentage (in bps) of the previous bid a prover can offer and still have a successful bid
    /// @dev This is used to prevent gas wars where the new prover undercuts the current prover by just a few wei
    uint256 public immutable maxBidPercentage;
    /// @notice The time window after which a publication is considered old enough and if the prover hasn't proven it
    /// yet can be evicted
    uint256 public immutable livenessWindow;
    /// @notice Time delay before a new prover takes over after a successful bid
    /// @dev The reason we don't allow this to happen immediately is to allow enough time for other provers to bid,
    /// prepare their hardware and to ensure no prover's window is too short
    uint256 public immutable successionDelay;
    /// @notice The delay after which the current prover can exit, or is removed if evicted because they are inactive
    /// @dev The reason we don't allow this to happen immediately is to allow enough time for other provers to bid
    /// and to prepare their hardware
    uint256 public immutable exitDelay;
    ///@notice The time window for a prover to submit a valid proof after their period ends
    uint256 public immutable provingWindow;
    /// @notice The minimum stake required to be a prover
    /// @dev This should be enough to cover the cost of a new prover if the current prover becomes inactive
    uint256 public immutable livenessBond;
    /// @notice The percentage(in bps) of the liveness bond that the evictor gets as an incentive
    uint256 public immutable evictorIncentivePercentage;
    /// @notice The percentage(in bps) of the liveness bond (at the moment of the slashing) that is burned when a
    /// prover is slashed
    uint256 public immutable burnedStakePercentage;

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
        uint256 _initialFee,
        ProverManagerConfig memory _config
    ) payable {
        maxBidPercentage = _config.maxBidPercentage;
        livenessWindow = _config.livenessWindow;
        successionDelay = _config.successionDelay;
        exitDelay = _config.exitDelay;
        provingWindow = _config.provingWindow;
        livenessBond = _config.livenessBond;
        evictorIncentivePercentage = _config.evictorIncentivePercentage;
        burnedStakePercentage = _config.burnedStakePercentage;
        inbox = _inbox;
        checkpointTracker = ICheckpointTracker(_checkpointTracker);
        publicationFeed = IPublicationFeed(_publicationFeed);

        // Initialize the first period with a known prover and a set fee
        // Start at period 1 so every period has a previous one (and an implicit start timestamp)
        // use block.timestamp - 1 as period 0's end timestamp so publications in this block are
        // part of period 1. We assume no relevant publications occur before this contract is deployed.
        Period storage p0 = _periods[0];
        p0.end = p0.deadline = block.timestamp - 1;

        currentPeriodId = 1;
        emit NewPeriod(1);

        require(msg.value >= _config.livenessBond, "Insufficient balance for liveness bond");
        Period storage p1 = _periods[1];
        p1.prover = _initialProver;
        p1.fee = _initialFee;
        p1.stake = _config.livenessBond;
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
    // TODO: deal with delayed publications
    function payPublicationFee(address proposer, bool isDelayed) external payable {
        require(msg.sender == inbox, "Only the Inbox contract can call this function");

        // Accept additional deposit if sent
        if (msg.value > 0) {
            _deposit(proposer, msg.value);
        }

        uint256 periodId = currentPeriodId;

        uint256 periodEnd = _periods[periodId].end;
        if (periodEnd != 0 && block.timestamp > periodEnd) {
            // Advance to the next period
            currentPeriodId = ++periodId;
            emit NewPeriod(periodId);
        }

        // Deduct fee from proposer's balance
        balances[proposer] -= _periods[periodId].fee;
    }

    /// @inheritdoc IProverManager
    /// @dev The offered fee has to be at most `maxBidPercentage` of the current best price.
    /// @dev The current best price may be the current prover's fee or the fee of the next bid, depending on whether the
    /// period is active or not.
    /// An active period is one that doesn't have an `end` timestamp yet.
    function bid(uint256 offeredFee) external {
        uint256 currentPeriod = currentPeriodId;
        Period storage _currentPeriod = _periods[currentPeriod];
        Period storage _nextPeriod = _periods[currentPeriod + 1];
        uint256 requiredMaxFee;
        if (_currentPeriod.end == 0) {
            // If the period is still active the bid has to be lower
            uint256 currentFee = _currentPeriod.fee;
            requiredMaxFee = _calculatePercentage(currentFee, maxBidPercentage);
            require(offeredFee <= requiredMaxFee, "Offered fee not low enough");

            uint256 periodEnd = block.timestamp + successionDelay;
            _finalizePeriod(_currentPeriod, periodEnd, periodEnd + provingWindow);
        } else {
            address _nextProverAddress = _nextPeriod.prover;
            if (_nextProverAddress != address(0)) {
                // If there's already a bid for the next period the bid has to be lower
                uint256 nextFee = _nextPeriod.fee;
                requiredMaxFee = _calculatePercentage(nextFee, maxBidPercentage);
                require(offeredFee <= requiredMaxFee, "Offered fee not low enough");

                // Refund the liveness bond to the losing bid
                balances[_nextProverAddress] += _nextPeriod.stake;
            }
        }

        // Record the next period info
        uint256 _livenessBond = livenessBond;
        _updatePeriod(_nextPeriod, msg.sender, offeredFee, _livenessBond);

        emit ProverOffer(msg.sender, currentPeriod + 1, offeredFee, _livenessBond);
    }

    /// @inheritdoc IProverManager
    /// @dev This can be called by anyone, and they get `evictorIncentivePercentage` of the liveness bond as an
    /// incentive.
    function evictProver(IPublicationFeed.PublicationHeader calldata publicationHeader) external {
        require(publicationFeed.validateHeader(publicationHeader), "Publication hash does not match");

        uint256 publicationTimestamp = publicationHeader.timestamp;
        require(publicationTimestamp + livenessWindow < block.timestamp, "Publication is not old enough");

        Period storage period = _periods[currentPeriodId];
        require(period.end == 0, "Proving period is not active");

        ICheckpointTracker.Checkpoint memory lastProven = checkpointTracker.getProvenCheckpoint();
        require(publicationHeader.id > lastProven.publicationId, "Publication has been proven");

        uint256 periodEnd = block.timestamp + exitDelay;
        // We use this to mark the prover as evicted
        _finalizePeriod(period, periodEnd, periodEnd);

        // Reward the evictor and slash the prover
        uint256 evictorIncentive = _calculatePercentage(period.stake, evictorIncentivePercentage);
        balances[msg.sender] += evictorIncentive;
        period.stake -= evictorIncentive;

        emit ProverEvicted(period.prover, msg.sender, periodEnd, period.stake);
    }

    /// @inheritdoc IProverManager
    /// @dev The prover still has to wait for the `exitDelay` to allow other provers to bid for the role.
    /// @dev The liveness bond can only be withdrawn once the period has been fully proven.
    function exit() external {
        Period storage period = _periods[currentPeriodId];
        address _prover = period.prover;
        require(msg.sender == _prover, "Not current prover");
        require(period.end == 0, "Prover already exited");

        uint256 periodEnd = block.timestamp + exitDelay;
        uint256 _provingDeadline = periodEnd + provingWindow;
        _finalizePeriod(period, periodEnd, _provingDeadline);

        emit ProverExited(_prover, periodEnd, _provingDeadline);
    }

    /// @inheritdoc IProverManager
    function claimProvingVacancy(uint256 fee) external {
        uint256 periodId = currentPeriodId;
        Period storage period = _periods[periodId];
        require(period.prover == address(0) && period.end == 0, "No proving vacancy");
        _finalizePeriod(period, block.timestamp, block.timestamp);

        Period storage nextPeriod = _periods[periodId + 1];
        _updatePeriod(nextPeriod, msg.sender, fee, livenessBond);
    }

    /// @inheritdoc IProverManager
    function prove(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader calldata firstPub,
        IPublicationFeed.PublicationHeader calldata lastPub,
        uint256 numPublications,
        bytes calldata proof,
        uint256 periodId
    ) external {
        Period storage period = _periods[periodId];
        uint256 previousPeriodEnd = _periods[periodId - 1].end;

        require(publicationFeed.validateHeader(lastPub), "Last publication does not exist");
        require(end.publicationId == lastPub.id, "Last publication does not match end checkpoint");
        require(period.end == 0 || lastPub.timestamp <= period.end, "Last publication is after the period");

        require(publicationFeed.validateHeader(firstPub), "First publication does not exist");
        require(start.publicationId + 1 == firstPub.id, "First publication not immediately after start checkpoint");
        require(firstPub.timestamp > previousPeriodEnd, "First publication is before the period");

        checkpointTracker.proveTransition(start, end, numPublications, proof);

        bool isClosed = block.timestamp > period.deadline && period.deadline != 0;
        if (isClosed) {
            period.prover = msg.sender;
            if (!period.pastDeadline) {
                // The first time this is called burn a % of the stake. Whoever proves the final publication in this
                // period can (eventually) call `finalizeClosedPeriod` to claim the remaining stake. In practice, a
                // single
                // prover will likely close the whole period with one proof.
                period.stake -= _calculatePercentage(period.stake, burnedStakePercentage);
                period.pastDeadline = true;
            }
        }
        balances[period.prover] += numPublications * period.fee;
    }

    /// @inheritdoc IProverManager
    function finalizeClosedPeriod(uint256 periodId, IPublicationFeed.PublicationHeader calldata provenPublication)
        external
    {
        ICheckpointTracker.Checkpoint memory lastProven = checkpointTracker.getProvenCheckpoint();
        require(publicationFeed.validateHeader(provenPublication), "Invalid publication header");
        require(lastProven.publicationId >= provenPublication.id, "Publication must be proven");

        Period storage period = _periods[periodId];
        require(provenPublication.timestamp > period.end, "Publication must be after period");
        balances[period.prover] += period.stake;
        period.stake = 0;
    }

    /// @inheritdoc IProposerFees
    function getCurrentFees() external view returns (uint256 fee, uint256 delayedFee) {
        uint256 currentPeriod = currentPeriodId;
        uint256 periodEnd = _periods[currentPeriod].end;
        if (periodEnd != 0 && block.timestamp > periodEnd) {
            currentPeriod++;
        }

        uint256 publicationFee = _periods[currentPeriod].fee;
        // TODO: implement delayed fee once we decide how to handle delayed publications
        return (publicationFee, publicationFee);
    }

    /// @notice Returns the period for a given period id
    /// @param periodId The id of the period
    /// @return _ The period
    function getPeriod(uint256 periodId) external view returns (Period memory) {
        return _periods[periodId];
    }

    /// @dev Increases `user`'s balance by `amount`
    function _deposit(address user, uint256 amount) private {
        balances[user] += amount;
        emit Deposit(user, amount);
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
        period.stake = stake; // overwrite previous value. We assume the previous value is zero or already returned
        balances[prover] -= stake;
    }

    /// @dev Sets a period's end and deadline timestamps
    /// @param period The period to finalize
    /// @param endTimestamp The timestamp when the period ends
    /// @param deadlineTimestamp The timestamp by which proofs must be submitted
    function _finalizePeriod(Period storage period, uint256 endTimestamp, uint256 deadlineTimestamp) private {
        period.end = endTimestamp;
        period.deadline = deadlineTimestamp;
    }
}
