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
    /// @notice The maximum percentage of the previous bid
    /// @dev This value needs to be expressed in basis points (4 decimal places)
    /// @dev This is used to prevent gas wars where the new prover undercuts the current prover by just a few wei
    uint256 public immutable maxBidPercentage;
    /// @notice The time window after which a publication is considered old enough and if the prover hasn't proven it
    /// yet
    /// can be evicted
    uint256 public immutable livenessWindow;
    /// @notice The delay after which the next prover becomes active
    /// @dev The reason we don't allow this to happen immediately is so that:
    /// 1. Other provers can bid for the role
    /// 2. Ensure the current prover window is not too short
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
    /// @notice The percentage of the liveness bond that the evictor gets as an incentive
    /// @dev This value needs to be expressed in basis points (4 decimals)
    uint256 public immutable evictorIncentivePercentage;
    /// @notice The percentage of the liveness bond (at the moment of the slashing) that is burned when a prover is
    /// slashed
    /// @dev This value needs to be expressed in basis points (4 decimals)
    uint256 public immutable burnedStakePercentage;

    /// @notice Common balances for proposers and provers
    mapping(address user => uint256 balance) public balances;
    /// @notice Periods represent proving windows
    /// @dev Most of the time we are dealing with the current period or next period (bids for the next period),
    /// but we need periods in the past to track publications that still need to be proven after the prover is
    /// evicted or exits
    mapping(uint256 periodId => Period) private _periods;
    /// @notice The current period
    uint256 public currentPeriodId;

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
        require(msg.value >= _config.livenessBond, "Insufficient balance for liveness bond");
        _periods[0].prover = _initialProver;
        _periods[0].stake = _config.livenessBond;
        _periods[0].fee = _initialFee;
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
    /// @dev The offered fee has to be at least `minUndercutPercentage` lower than the current best price.
    /// @dev The current best price may be the current prover's fee or the fee of the next bid, depending on a few
    /// conditions.
    function bid(uint256 offeredFee) external {
        uint256 currentPeriod = currentPeriodId;
        Period storage _currentPeriod = _periods[currentPeriod];
        Period storage _nextPeriod = _periods[currentPeriod + 1];
        uint256 requiredMaxFee;
        if (_isPeriodActive(_currentPeriod.end)) {
            // If the period is still active the bid has to be lower
            uint256 currentFee = _currentPeriod.fee;
            requiredMaxFee = _calculatePercentage(currentFee, maxBidPercentage);
            require(offeredFee <= requiredMaxFee, "Offered fee not low enough");

            uint256 periodEnd = block.timestamp + successionDelay;
            _currentPeriod.end = periodEnd;
            _currentPeriod.deadline = periodEnd + provingWindow;
        } else {
            address _nextProverAddress = _nextPeriod.prover;
            if (_isBidded(_nextProverAddress)) {
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
    function evictProver(
        uint256 publicationId,
        IPublicationFeed.PublicationHeader calldata publicationHeader,
        ICheckpointTracker.Checkpoint calldata lastProven
    ) external {
        require(publicationFeed.validateHeader(publicationHeader, publicationId), "Publication hash does not match");

        uint256 publicationTimestamp = publicationHeader.timestamp;
        require(publicationTimestamp + livenessWindow < block.timestamp, "Publication is not old enough");

        Period storage period = _periods[currentPeriodId];
        require(period.end == 0, "Proving period is not active");

        bytes32 lastProvenHash = keccak256(abi.encode(lastProven));
        require(lastProvenHash == checkpointTracker.provenHash(), "Incorrect lastProven checkpoint");
        require(publicationHeader.id > lastProven.publicationId, "Publication has been proven");

        uint256 periodEnd = block.timestamp + exitDelay;
        // We use this to mark the prover as evicted
        period.deadline = periodEnd;
        period.end = periodEnd;

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
        period.end = periodEnd;
        period.deadline = _provingDeadline;

        emit ProverExited(_prover, periodEnd, _provingDeadline);
    }

    /// @inheritdoc IProverManager
    function claimProvingVacancy(uint256 fee) external {
        uint256 periodId = currentPeriodId;
        Period storage period = _periods[periodId];
        require(period.prover == address(0) && period.end == 0, "No proving vacancy");

        // Advance to the next period
        currentPeriodId = ++periodId;
        emit NewPeriod(periodId);

        period = _periods[periodId];
        _updatePeriod(period, msg.sender, fee, livenessBond);
    }

    /// @inheritdoc IProverManager
    function proveOpenPeriod(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader calldata startPublicationHeader,
        IPublicationFeed.PublicationHeader calldata endPublicationHeader,
        uint256 numPublications,
        bytes calldata proof,
        uint256 periodId
    ) external {
        Period storage period = _periods[periodId];
        uint256 periodEnd = period.end;
        require(period.deadline == 0 || block.timestamp <= period.deadline, "Deadline has passed");

        uint256 previousPeriodEnd = 0;
        if (periodId > 0) {
            Period storage previousPeriod = _periods[periodId - 1];
            previousPeriodEnd = previousPeriod.end;
        }

        _validateBasePublications(
            start, end, startPublicationHeader, endPublicationHeader, periodEnd, previousPeriodEnd
        );

        checkpointTracker.proveTransition(start, end, numPublications, proof);
        balances[period.prover] += numPublications * period.fee;
    }

    /// @inheritdoc IProverManager
    /// @dev This function pays the offender prover for the work they already did, and distributes remaining fees and a
    /// portion of the liveness bond to the new prover.
    /// @dev A portion of the liveness bond is burned by locking it in the contract forever.
    function proveClosedPeriod(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader calldata startPublicationHeader,
        IPublicationFeed.PublicationHeader calldata endPublicationHeader,
        uint256 numPublications,
        bytes calldata proof,
        uint256 periodId
    ) external {
        Period storage period = _periods[periodId];
        uint256 periodEnd = period.end;
        require(period.deadline != 0 && block.timestamp > period.deadline, "The period is still open");

        uint256 previousPeriodEnd = 0;
        if (periodId > 0) {
            Period storage previousPeriod = _periods[periodId - 1];
            previousPeriodEnd = previousPeriod.end;
        }

        _validateBasePublications(
            start, end, startPublicationHeader, endPublicationHeader, periodEnd, previousPeriodEnd
        );

        checkpointTracker.proveTransition(start, end, numPublications, proof);
        balances[msg.sender] += period.fee * numPublications;

        // Apply a burn percentage on every call to this function. Whoever proves the final publication in this period
        // can (eventually) call `finalizeClosedPeriod` to claim the remaining stake. In practice, a single prover will
        // likely close the whole period with one proof.
        period.stake -= _calculatePercentage(period.stake, burnedStakePercentage);
        period.prover = msg.sender;
    }

    /// @inheritdoc IProverManager
    function finalizeClosedPeriod(
        uint256 periodId,
        ICheckpointTracker.Checkpoint calldata lastProven,
        bytes calldata provenPublicationHeaderBytes
    ) external {
        Period storage period = _periods[periodId];
        require(_isClosed(period.end, lastProven, provenPublicationHeaderBytes), "Period not closed");

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
        return amount * bps / 10_000;
    }

    /// @dev Validates the start and end publication headers and ensures that they are within the period.
    /// @param start The initial checkpoint before the transition
    /// @param end The final checkpoint after the transition
    /// @param startPub The start publication header
    /// @param endPub The end publication header
    /// @param periodEnd The end of the period. If 0, the period is still active
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
        require(periodEnd == 0 || endPub.timestamp <= periodEnd, "End publication is not within the period");

        require(publicationFeed.validateHeader(startPub, start.publicationId), "Start publication hash does not match");
        require(startPub.timestamp > previousPeriodEnd, "Start publication is not within the period");
    }

    /// @dev Checks if a period is active based on its end timestamp
    /// @param end The end timestamp of the period
    /// @return True if the period is active, false otherwise
    function _isPeriodActive(uint256 end) private pure returns (bool) {
        return end == 0;
    }

    /// @dev Checks if a period is already bidded
    /// @param prover The address of the prover
    /// @return True if someone has already bid for the period, false otherwise
    function _isBidded(address prover) private pure returns (bool) {
        return prover != address(0);
    }

    function _isClosed(uint256 periodEnd, ICheckpointTracker.Checkpoint calldata lastProven, bytes calldata headerBytes)
        private
        view
        returns (bool)
    {
        bytes32 lastProvenHash = keccak256(abi.encode(lastProven));
        require(lastProvenHash == checkpointTracker.provenHash(), "Incorrect lastProven checkpoint");

        // Case 1: all publications are proven and the period is over
        if (publicationFeed.getNextPublicationId() == lastProven.publicationId + 1 && block.timestamp > periodEnd) {
            return true;
        }

        // Case 2: there is a proven publication that occurs after the period
        IPublicationFeed.PublicationHeader memory header = abi.decode(headerBytes, (IPublicationFeed.PublicationHeader));
        require(publicationFeed.validateHeader(header, header.id), "Invalid publication header");
        if (lastProven.publicationId >= header.id && header.timestamp > periodEnd) {
            return true;
        }

        // this does not necessarily imply the period is open, merely that we have not proven it to be closed
        // notably, we do not handle the scenario where the first unproven publication is after the period
        // that publication will eventually be proven and then Case 2 will apply
        return false;
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
}
