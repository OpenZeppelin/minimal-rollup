// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibPercentage} from "../libs/LibPercentage.sol";
import {LibProvingPeriod} from "../libs/LibProvingPeriod.sol";
import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {IProposerFees} from "./IProposerFees.sol";
import {IProverManager} from "./IProverManager.sol";
import {IPublicationFeed} from "./IPublicationFeed.sol";

abstract contract BaseProverManager is IProposerFees, IProverManager {
    using LibPercentage for uint96;
    using LibProvingPeriod for LibProvingPeriod.Period;

    address public immutable inbox;
    ICheckpointTracker public immutable checkpointTracker;
    IPublicationFeed public immutable publicationFeed;

    /// @notice Common balances for proposers and provers
    mapping(address user => uint256 balance) private _balances;
    /// @notice The current period
    uint256 private _currentPeriodId;
    /// @dev Periods represent proving windows
    mapping(uint256 periodId => LibProvingPeriod.Period) private _periods;

    /// @dev Initializes the contract state and deposits the initial prover's liveness bond.
    /// The constructor also calls `_claimProvingVacancy`. Publications will actually start in period 1.
    /// @param _inbox The address of the inbox contract
    /// @param _checkpointTracker The address of the checkpoint tracker contract
    /// @param _publicationFeed The address of the publication feed contract
    /// @param _initialProver The address that will be designated as the initial prover
    /// @param _initialFee The fee for the initial period
    /// @param _initialDeposit The initial deposit that will be added to the `_initialProver`'s balance
    constructor(
        address _inbox,
        address _checkpointTracker,
        address _publicationFeed,
        address _initialProver,
        uint96 _initialFee,
        uint256 _initialDeposit
    ) {
        require(_inbox != address(0), "Inbox address cannot be 0");
        require(_checkpointTracker != address(0), "Checkpoint tracker address cannot be 0");
        require(_publicationFeed != address(0), "Publication feed address cannot be 0");
        require(_initialProver != address(0), "Initial prover address cannot be 0");

        inbox = _inbox;
        checkpointTracker = ICheckpointTracker(_checkpointTracker);
        publicationFeed = IPublicationFeed(_publicationFeed);

        // Close the first period so every period has a previous one (and an implicit start timestamp)
        // The initial fee and prover will take effect in the block after this one
        _deposit(_initialProver, _initialDeposit);
        _claimProvingVacancy(_initialFee, _initialProver);
    }

    /// @notice Withdraw available(unlocked) funds.
    /// @param amount The amount to withdraw
    function withdraw(uint256 amount) external {
        _decreaseBalance(msg.sender, amount);
        _transferOut(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }

    /// @inheritdoc IProposerFees
    /// @dev This function advances to the next period if the current period has ended.
    function payPublicationFee(address proposer, bool isDelayed) external {
        require(msg.sender == inbox, "Only the Inbox contract can call this function");

        uint256 periodId = _currentPeriodId;

        if (_periods[periodId].isComplete()) {
            periodId = _advancePeriod();
        }

        _decreaseBalance(proposer, _periods[periodId].publicationFee(isDelayed));
    }

    /// @inheritdoc IProverManager
    /// @dev The offered fee has to be at most `maxBidPercentage` of the current best price.
    /// @dev The current best price may be the current prover's fee or the fee of the next bid, depending on whether the
    /// period is open or closed.
    function bid(uint96 offeredFee) external {
        uint256 currentPeriodId_ = _currentPeriodId;
        LibProvingPeriod.Period storage currentPeriod = _periods[currentPeriodId_];
        LibProvingPeriod.Period storage nextPeriod = _periods[currentPeriodId_ + 1];
        if (currentPeriod.isOpen()) {
            _ensureSufficientUnderbid(currentPeriod.fee, offeredFee);
            currentPeriod.close(_successionDelay(), _provingWindow());
        } else if (nextPeriod.isInitialized()) {
            _ensureSufficientUnderbid(nextPeriod.fee, offeredFee);
            // Refund the liveness bond to the losing bid
            _increaseBalance(nextPeriod.prover, nextPeriod.stake);
        }

        // Record the next period info
        _decreaseBalance(msg.sender, _livenessBond());
        nextPeriod.init(msg.sender, offeredFee, _delayedFeePercentage(), _livenessBond());

        emit ProverOffer(msg.sender, currentPeriodId_ + 1, offeredFee, _livenessBond());
    }

    /// @inheritdoc IProverManager
    /// @dev This can be called by anyone, and they get `evictorIncentivePercentage` of the liveness bond as an
    /// incentive.
    function evictProver(IPublicationFeed.PublicationHeader calldata publicationHeader) external {
        require(publicationFeed.validateHeader(publicationHeader), "Invalid publication");
        require(publicationHeader.timestamp + _livenessWindow() < block.timestamp, "Publication is not old enough");

        LibProvingPeriod.Period storage period = _periods[_currentPeriodId];
        require(period.isOpen(), "Proving period is closed");

        ICheckpointTracker.Checkpoint memory lastProven = checkpointTracker.getProvenCheckpoint();
        require(publicationHeader.id > lastProven.publicationId, "Publication has been proven");

        // We use this to mark the prover as evicted
        (uint40 end,) = period.close(_exitDelay(), 0);

        // Reward the evictor and slash the prover
        uint96 evictorIncentive = period.stake.scaleBy(_evictorIncentivePercentage());
        _increaseBalance(msg.sender, evictorIncentive);
        period.slash(evictorIncentive);

        emit ProverEvicted(period.prover, msg.sender, end, period.stake);
    }

    /// @inheritdoc IProverManager
    /// @dev The prover still has to wait for the `exitDelay` to allow other provers to bid for the role.
    /// @dev The liveness bond can only be withdrawn once the period has been fully proven.
    function exit() external {
        LibProvingPeriod.Period storage period = _periods[_currentPeriodId];
        address prover = period.prover;
        require(msg.sender == prover, "Not current prover");
        require(period.isOpen(), "Period already closed");

        (uint40 end, uint40 deadline) = period.close(_exitDelay(), _provingWindow());
        emit ProverExited(prover, end, deadline);
    }

    /// @inheritdoc IProverManager
    function claimProvingVacancy(uint96 fee) external {
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
        LibProvingPeriod.Period storage period = _periods[periodId];
        uint40 previousPeriodEnd = periodId > 0 ? _periods[periodId - 1].end : 0;

        require(publicationFeed.validateHeader(lastPub), "Last publication does not exist");
        require(end.publicationId == lastPub.id, "Last publication does not match end checkpoint");
        require(period.isNotBefore(lastPub.timestamp), "Last publication is after the period");

        require(publicationFeed.validateHeader(firstPub), "First publication does not exist");
        require(start.publicationId + 1 == firstPub.id, "First publication not immediately after start checkpoint");
        require(firstPub.timestamp > previousPeriodEnd, "First publication is before the period");

        checkpointTracker.proveTransition(start, end, numPublications, numDelayedPublications, proof);

        if (period.isDeadlinePassed()) {
            period.assignReward(msg.sender);
        }

        uint96 baseFee = period.fee;
        uint256 regularPubFee = (numPublications - numDelayedPublications) * baseFee;

        uint256 delayedPubFee;

        if (numDelayedPublications > 0) {
            uint96 delayedFee = baseFee.scaleBy(period.delayedFeePercentage, LibPercentage.PERCENT);
            delayedPubFee = numDelayedPublications * delayedFee;
        }

        _increaseBalance(period.prover, regularPubFee + delayedPubFee);
    }

    /// @inheritdoc IProverManager
    function finalizePastPeriod(uint256 periodId, IPublicationFeed.PublicationHeader calldata provenPublication)
        external
    {
        ICheckpointTracker.Checkpoint memory lastProven = checkpointTracker.getProvenCheckpoint();
        require(publicationFeed.validateHeader(provenPublication), "Invalid publication header");
        require(lastProven.publicationId >= provenPublication.id, "Publication must be proven");

        LibProvingPeriod.Period storage period = _periods[periodId];
        require(provenPublication.timestamp > period.end, "Publication must be after period");

        uint96 stake = period.stake;
        _increaseBalance(period.prover, period.pastDeadline ? stake.scaleBy(_rewardPercentage()) : stake);
        period.stake = 0;
    }

    /// @inheritdoc IProposerFees
    function getCurrentFees() external view returns (uint96 fee, uint96 delayedFee) {
        uint256 currentPeriod = _currentPeriodId;
        if (_periods[currentPeriod].isComplete()) {
            // can never overflow
            unchecked {
                ++currentPeriod;
            }
        }

        LibProvingPeriod.Period storage period = _periods[currentPeriod];
        fee = period.fee;
        delayedFee = fee.scaleBy(period.delayedFeePercentage, LibPercentage.PERCENT);
    }

    /// @notice Get the balance of a user
    /// @param user The address of the user
    /// @return The balance of the user
    function balances(address user) public view returns (uint256) {
        return _balances[user];
    }

    /// @notice Get the current period ID
    /// @return The current period ID
    function currentPeriodId() public view returns (uint256) {
        return _currentPeriodId;
    }

    /// @notice Returns the period for a given period id
    /// @param periodId The id of the period
    /// @return _ The period
    function getPeriod(uint256 periodId) external view returns (LibProvingPeriod.Period memory) {
        return _periods[periodId];
    }

    /// @dev Ensure the offered fee is low enough. It must be at most `maxBidPercentage` of the fee it is outbidding
    /// @param fee The fee to be outbid (either the current period's fee or next period's winning fee)
    /// @param offeredFee The new bid
    function _ensureSufficientUnderbid(uint96 fee, uint96 offeredFee) internal view virtual {
        uint96 requiredMaxFee = fee.scaleBy(_maxBidPercentage());
        require(offeredFee <= requiredMaxFee, "Offered fee not low enough");
    }

    /// @dev Returns the maximum percentage (in bps) of the previous bid a prover can offer and still have a successful
    /// bid
    /// @return _ The maximum bid percentage value
    function _maxBidPercentage() internal view virtual returns (uint16);

    /// @dev Returns the time window after which a publication is considered old enough for prover eviction
    /// @return _ The liveness window value in seconds
    function _livenessWindow() internal view virtual returns (uint40);

    /// @dev Returns the time delay before a new prover takes over after a successful bid
    /// @return _ The succession delay value in seconds
    function _successionDelay() internal view virtual returns (uint40);

    /// @dev Returns the delay after which the current prover can exit, or is removed if evicted
    /// @return _ The exit delay value in seconds
    function _exitDelay() internal view virtual returns (uint40);

    /// @dev Returns the time window for a prover to submit a valid proof after their period ends
    /// @return _ The proving window value in seconds
    function _provingWindow() internal view virtual returns (uint40);

    /// @dev Returns the minimum stake required to be a prover
    /// @return _ The liveness bond value in wei
    function _livenessBond() internal view virtual returns (uint96);

    /// @dev Returns the percentage (in bps) of the liveness bond that the evictor gets as an incentive
    /// @return _ The evictor incentive percentage
    function _evictorIncentivePercentage() internal view virtual returns (uint16);

    /// @dev Returns the percentage (in bps) of the remaining liveness bond rewarded to the prover
    /// @return _ The reward percentage
    function _rewardPercentage() internal view virtual returns (uint16);

    /// @dev The percentage of the fee that is charged for delayed publications
    /// @dev It is recommended to set this to >100 since delayed publications should usually be charged at a higher rate
    /// @return _ The multiplier as a percentage (two decimals). This value should usually be greater than 100 (100%).
    function _delayedFeePercentage() internal view virtual returns (uint16);

    /// @dev Increases `user`'s balance by `amount` and emits a `Deposit` event
    function _deposit(address user, uint256 amount) internal {
        _balances[user] += amount;
        emit Deposit(user, amount);
    }

    /// @dev Implements currency-specific transfer logic for withdrawals
    function _transferOut(address to, uint256 amount) internal virtual;

    /// @dev implementation of `IProverManager.claimProvingVacancy` with the option to specify a prover
    /// This also lets the constructor claim the first vacancy on behalf of _initialProver
    /// @param fee The fee to be set for the new period
    /// @param prover The address of the prover to be set for the new period
    function _claimProvingVacancy(uint96 fee, address prover) private {
        uint256 periodId = _currentPeriodId;
        LibProvingPeriod.Period storage period = _periods[periodId];
        require(period.prover == address(0) && period.isOpen(), "No proving vacancy");
        period.close(0, 0);

        LibProvingPeriod.Period storage nextPeriod = _periods[periodId + 1];
        _decreaseBalance(prover, _livenessBond());
        nextPeriod.init(prover, fee, _delayedFeePercentage(), _livenessBond());
    }

    /// @notice mark the next period as active. Future publications will be assigned to the new period
    function _advancePeriod() private returns (uint256 periodId) {
        _currentPeriodId++;
        periodId = _currentPeriodId;
        emit NewPeriod(periodId);
    }

    function _increaseBalance(address user, uint256 amount) internal {
        _balances[user] += amount;
    }

    function _decreaseBalance(address user, uint256 amount) internal {
        _balances[user] -= amount;
    }
}
