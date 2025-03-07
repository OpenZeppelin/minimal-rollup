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
        uint256 accumulatedFees; // the fees accumulated by proposers' publications for this period
        uint256 fee; // per-publication fee (in wei)
        uint256 end; // the end of the period(this may happen because the prover exits, is evicted or outbid)
        uint256 deadline; // the time by which the prover needs to submit a proof(this is only needed after a prover
            // exits or is replaced)
        bool evicted; // flag that signals the prover has been evicted and should be slashed
    }

    address public immutable inbox;
    ICheckpointTracker public immutable checkpointTracker;
    IPublicationFeed public immutable publicationFeed;

    // -- Configuration parameters --
    /// @notice The minimum percentage by which the new bid has to be lower than the current best value
    /// @dev This value needs to be expressed in basis points
    /// @dev This is used to prevent gas wars where the new prover undercuts the current prover by just a few wei
    uint256 public minUndercutPercentage;
    /// @notice The time window after which a publication is considered old enough and if the prover hasn't poven it yet
    /// can be evicted
    uint256 public livenessWindow;
    /// @notice The delay after which the next prover becomes active
    /// @dev The reason we don't allow this to happen immediately is so that:
    /// 1. Other provers can bid for the role
    /// 2. Ensure the current prover window is not too short
    uint256 public succesionDelay;
    /// @notice The delay after which the current prover can exit, or is removed if evicted because they are inactive
    /// @dev The reason we don't allow this to happen immediately is to allow enough time for other provers to bid
    /// and to prepare their hardware
    uint256 public exitDelay;
    /// @notice The multiplier for delayed publications
    /// @dev Delayed publications are charged at a higher fee, since they can potentially be much larger than regular
    /// publications
    uint256 public delayedFeeMultiplier;
    ///@notice The deadline for a prover to submit a valid proof after their period ends
    uint256 public provingDeadline;
    /// @notice The minimum stake required to be a prover
    /// @dev This should be enough to cover the cost of a new prover if the current prover becomes inactive
    uint256 public livenessBond;
    /// @notice The percentage of the liveness bond that the evictor gets as an incentive
    /// @dev This value needs to be expressed in basis points
    uint256 public evictorIncentivePercentage;
    /// @notice The percentage of the liveness bond (at the moment of the slashing) that is burned when a prover is
    /// slashed
    /// @dev This value needs to be expressed in basis points
    uint256 public burnedStakePercentage;

    /// @notice Common balances for proposers and provers
    mapping(address => uint256) public balances;
    /// @notice Periods represent proving windows
    /// @dev Most of the time we are dealing with the current period or next period (bids for the next period),
    /// but we need periods in the past to track publications that still need to be proven after the prover is
    /// evicted or exits
    mapping(uint256 periodId => Period period) public periods;
    /// @notice The current period
    uint256 public currentPeriodId;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event ProverOffer(address indexed proposer, uint256 fee, uint256 stake);
    event ProverSlashed(address indexed prover, address indexed slasher, uint256 slashedAmount);
    event ProverEvicted(address indexed prover, address indexed evictor, uint256 periodEnd, uint256 livenessBond);
    event ProverExited(address indexed prover, uint256 periodEnd, uint256 provingDeadline);

    constructor(
        uint256 _minUndercutPercentage,
        uint256 _livenessWindow,
        uint256 _succesionDelay,
        uint256 _exitDelay,
        uint256 _delayedFeeMultiplier,
        uint256 _provingDeadline,
        uint256 _livenessBond,
        uint256 _evictorIncentivePercentage,
        uint256 _burnedStakePercentage,
        address _inbox,
        address _checkpointTracker,
        address _publicationFeed,
        address _initialProover,
        uint256 _initialFee
    ) payable {
        minUndercutPercentage = _minUndercutPercentage;
        livenessWindow = _livenessWindow;
        succesionDelay = _succesionDelay;
        exitDelay = _exitDelay;
        delayedFeeMultiplier = _delayedFeeMultiplier;
        provingDeadline = _provingDeadline;
        livenessBond = _livenessBond;
        evictorIncentivePercentage = _evictorIncentivePercentage;
        burnedStakePercentage = _burnedStakePercentage;
        inbox = _inbox;
        checkpointTracker = ICheckpointTracker(_checkpointTracker);
        publicationFeed = IPublicationFeed(_publicationFeed);

        // Initialize the first period with a known prover and a set fee
        require(msg.value >= _livenessBond, "Insufficient balance for liveness bond");
        periods[0].prover = _initialProover;
        periods[0].stake = _livenessBond;
        periods[0].fee = _initialFee;
    }

    /// @notice Deposit ETH into the contract. The deposit can be used both for opting in as a prover or proposer
    function deposit() external payable {
        balances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw available(unlocked) funds.
    function withdraw(uint256 amount) external {
        balances[msg.sender] -= amount;

        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, "Withdrawal failed");
        emit Withdrawal(msg.sender, amount);
    }

    /// @inheritdoc IProposerFees
    /// @dev This function advances to the next period if the current period has ended.
    function payPublicationFee(address proposer, bool isDelayed) external payable {
        require(msg.sender == inbox, "Only the Inbox contract can call this function");

        // Accept additional deposit if sent
        if (msg.value > 0) {
            balances[proposer] += msg.value;
            emit Deposit(proposer, msg.value);
        }

        uint256 currentPeriod = currentPeriodId;

        if (block.timestamp > periods[currentPeriod].end) {
            // Advance to the next period
            currentPeriodId++;
            currentPeriod++;
        }

        uint256 requiredFee = periods[currentPeriod].fee;
        //TODO: I'm not sure this is the correct way to deal with this
        if (isDelayed) {
            requiredFee *= delayedFeeMultiplier;
        }

        // Deduct fee from proposer's balance and add to accumulated fees
        balances[proposer] -= requiredFee;
        periods[currentPeriod].accumulatedFees += requiredFee;
    }

    /// @inheritdoc IProverManager
    /// @dev The offered fee has to be at least `minUndercutPercentage` lower than the current best price.
    /// @dev The current best price may be the current prover's fee or the fee of the next bid, depending on a few
    /// conditions.
    function bid(uint256 offeredFee) external {
        uint256 _livenessBond = livenessBond;
        require(balances[msg.sender] >= _livenessBond, "Insufficient balance for liveness bond");

        uint256 currentPeriod = currentPeriodId;
        Period storage _currentPeriod = periods[currentPeriod];
        Period storage _nextPeriod = periods[currentPeriod + 1];
        uint256 requiredMaxFee;
        if (_currentPeriod.end == 0) {
            // If the period is still active the bid has to be lower
            uint256 currentFee = _currentPeriod.fee;
            requiredMaxFee = currentFee - calculatePercentage(currentFee, minUndercutPercentage);
            require(offeredFee <= requiredMaxFee, "Offered fee not low enough");

            uint256 periodEnd = block.timestamp + succesionDelay;
            _currentPeriod.end = periodEnd;
            _currentPeriod.deadline = periodEnd + provingDeadline;
        } else {
            address _nextProverAddress = _nextPeriod.prover;
            if (_nextProverAddress != address(0)) {
                // If there's already a bid for the next period the bid has to be lower
                uint256 nextFee = _nextPeriod.fee;
                requiredMaxFee = nextFee - calculatePercentage(nextFee, minUndercutPercentage);
                require(offeredFee <= requiredMaxFee, "Offered fee not low enough");

                // Refund the liveness bond to the losing bid
                balances[_nextProverAddress] += _nextPeriod.stake;
            }
        }

        // Record the next period info
        _nextPeriod.prover = msg.sender;
        _nextPeriod.fee = offeredFee;
        _nextPeriod.stake = _livenessBond;
        balances[msg.sender] -= _livenessBond;

        emit ProverOffer(msg.sender, offeredFee, _livenessBond);
    }

    /// @inheritdoc IProverManager
    /// @dev This can be called by anyone, and they get `evictorIncentivePercentage` of the liveness bond as an
    /// incentive.
    function evictProver(uint256 publicationId, IPublicationFeed.PublicationHeader calldata publicationHeader)
        external
    {
        require(publicationFeed.validateHeader(publicationHeader, publicationId), "Publication hash does not match");

        uint256 publicationTimestamp = publicationHeader.timestamp;
        require(publicationTimestamp + livenessWindow < block.timestamp, "Publication is not old enough");

        uint256 periodEnd = block.timestamp + exitDelay;
        Period storage period = periods[currentPeriodId];
        period.evicted = true;
        period.end = periodEnd;

        // Reward the evictor and slash the prover
        uint256 evictorIncentive = calculatePercentage(period.stake, evictorIncentivePercentage);
        balances[msg.sender] += evictorIncentive;
        period.stake -= evictorIncentive;

        emit ProverEvicted(period.prover, msg.sender, periodEnd, period.stake);
    }

    /// @inheritdoc IProverManager
    /// @dev The prover still has to wait for the `exitDelay` to allow other provers to bid for the role.
    /// @dev The liveness bond and the accumulated fees can only be withdrawn once the period has been fully proven.
    function exit() external {
        Period storage period = periods[currentPeriodId];
        address _prover = period.prover;
        require(msg.sender == _prover, "Not current prover");
        require(period.end == 0, "Prover already exited");

        uint256 periodEnd = block.timestamp + exitDelay;
        uint256 _provingDeadline = periodEnd + provingDeadline;
        period.end = periodEnd;
        period.deadline = _provingDeadline;

        emit ProverExited(_prover, periodEnd, _provingDeadline);
    }

    /// @inheritdoc IProverManager
    function proveOpenPeriod(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader calldata startPublicationHeader,
        IPublicationFeed.PublicationHeader calldata endPublicationHeader,
        bytes calldata nextPublicationHeaderBytes,
        bytes calldata proof,
        uint256 periodId
    ) external {
        Period storage period = periods[periodId];
        Period storage previousPeriod = periods[periodId - 1];
        require(block.timestamp <= period.deadline, "Deadline has passed");

        uint256 periodEnd = period.end;
        uint256 previousPeriodEnd = previousPeriod.end;

        _validateBasePublications(
            start, end, startPublicationHeader, endPublicationHeader, periodEnd, previousPeriodEnd
        );

        checkpointTracker.proveTransition(start, end, proof);

        if (nextPublicationHeaderBytes.length > 0) {
            // This means that the prover is claiming that they have finished all their publications for the period
            IPublicationFeed.PublicationHeader memory nextPub =
                abi.decode(nextPublicationHeaderBytes, (IPublicationFeed.PublicationHeader));
            _validateNextPublicationHeader(nextPub, end.publicationId + 1, periodEnd);

            // Finalize the period: transfer accumulated fees and stake.
            uint256 accumulatedFees = period.accumulatedFees;
            uint256 stake = period.stake;
            balances[period.prover] += accumulatedFees + stake;
        }
    }

    /// @inheritdoc IProverManager
    /// @dev This function pays the offender prover for the work they already did, and distributes remaining fees and a
    /// portion of the liveness bond to the new prover.
    /// @dev A portion of the liveness bond is burned by locking it in the contract forever.
    function proveClosedPeriod(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader[] calldata publicationHeadersToProve,
        IPublicationFeed.PublicationHeader calldata nextPublicationHeader,
        bytes calldata proof,
        uint256 periodId
    ) external {
        Period storage period = periods[periodId];
        Period storage previousPeriod = periods[periodId - 1];
        require(period.evicted || block.timestamp > period.deadline, "The period is still open");

        uint256 periodEnd = period.end;
        uint256 previousPeriodEnd = previousPeriod.end;
        uint256 numPubs = publicationHeadersToProve.length;
        IPublicationFeed.PublicationHeader memory startPub = publicationHeadersToProve[0];
        IPublicationFeed.PublicationHeader memory endPub = publicationHeadersToProve[numPubs - 1];

        _validatePublicationChain(publicationHeadersToProve);

        // Ensure that publications are inside the period
        require(endPub.timestamp < periodEnd, "End publication is not within the period");
        require(startPub.timestamp > previousPeriodEnd, "Start publication is not within the period");

        // Ensure that checkpoints actually match the publications
        require(start.publicationId == startPub.id, "Start checkpoint publication ID mismatch");
        require(end.publicationId == endPub.id, "End checkpoint publication ID mismatch");

        _validateNextPublicationHeader(nextPublicationHeader, end.publicationId + 1, periodEnd);

        checkpointTracker.proveTransition(start, end, proof);

        // Distribute the funds
        uint256 _livenessBond = period.stake;
        uint256 accumulatedFees = period.accumulatedFees;
        uint256 newProverFees = period.fee * numPubs;

        // Pay the designed prover for the work they already did
        balances[period.prover] += accumulatedFees - newProverFees;

        // Compensate the new prover(fees for the set of publications + a portion of the liveness bond)
        uint256 burnedStake = calculatePercentage(_livenessBond, burnedStakePercentage);
        uint256 livenessBondReward = _livenessBond - burnedStake;
        balances[msg.sender] += newProverFees + livenessBondReward;
    }

    /// @dev Calculates the percentage of a given numerator scaling up to avoid precision loss
    /// @param amount The number to calculate the percentage of
    /// @param bps The percentage expressed in basis points(https://muens.io/solidity-percentages)
    function calculatePercentage(uint256 amount, uint256 bps) private pure returns (uint256) {
        require((amount * bps) >= 10_000);
        return amount * bps / 10_000;
    }

    /// @dev Validates the start and end publication headers and ensures that they are within the period.
    /// @param start The initial checkpoint before the transition
    /// @param end The final checkpoint after the transition
    /// @param startPub The start publication header
    /// @param endPub The end publication header
    /// @param periodEnd The end of the period
    /// @param previousPeriodEnd The end of the previous period
    function _validateBasePublications(
        ICheckpointTracker.Checkpoint memory start,
        ICheckpointTracker.Checkpoint memory end,
        IPublicationFeed.PublicationHeader memory startPub,
        IPublicationFeed.PublicationHeader memory endPub,
        uint256 periodEnd,
        uint256 previousPeriodEnd
    ) private view {
        require(publicationFeed.validateHeader(endPub, end.publicationId), "End publication hash does not match");
        require(endPub.timestamp < periodEnd, "End publication is not within the period");

        require(publicationFeed.validateHeader(startPub, start.publicationId), "Start publication hash does not match");
        require(startPub.timestamp > previousPeriodEnd, "Start publication is not within the period");
    }

    /// @dev Validates the next publication header and ensures that it is after the period end.
    /// @param nextPub The next publication header
    /// @param expectedId The expected id of the next publication
    /// @param periodEnd The end of the period
    function _validateNextPublicationHeader(
        IPublicationFeed.PublicationHeader memory nextPub,
        uint256 expectedId,
        uint256 periodEnd
    ) private view {
        require(nextPub.id == expectedId, "This is not the next publication");
        require(nextPub.timestamp > periodEnd, "Next publication is not after the period end");
        require(publicationFeed.validateHeader(nextPub, nextPub.id), "Publication hash does not match");
    }

    /// @dev Validates a chain of publication headers.
    /// @param headers The chain of publication headers to validate
    function _validatePublicationChain(IPublicationFeed.PublicationHeader[] memory headers) private view {
        uint256 numPubs = headers.length;
        //Verify that all the publications are correct and linked together(they belong to this rollup)
        for (uint256 i = 1; i < numPubs; ++i) {
            require(publicationFeed.validateHeader(headers[i], headers[i].id), "Publication hash does not match");
            if (i > 0) {
                bytes32 prevHash = keccak256(abi.encode(headers[i - 1]));
                require(prevHash == headers[i].prevHash, "Previous publication hash does not match");
            }
        }
    }
}
