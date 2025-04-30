// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibPercentage} from "../libs/LibPercentage.sol";
import {LibProvingPeriod} from "../libs/LibProvingPeriod.sol";

import {BalanceAccounting} from "./BalanceAccounting.sol";

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {IProposerFees} from "./IProposerFees.sol";
import {IProverManager} from "./IProverManager.sol";
import {IPublicationFeed} from "./IPublicationFeed.sol";
import {ProverManagerConfig} from "./ProverManagerConfig.sol";

abstract contract BaseProverManager is IProposerFees, IProverManager, BalanceAccounting, ProverManagerConfig {
    using LibPercentage for uint96;
    using LibProvingPeriod for LibProvingPeriod.Period;

    address public immutable inbox;
    ICheckpointTracker public immutable checkpointTracker;
    IPublicationFeed public immutable publicationFeed;

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

        _increaseBalance(period.prover, period.totalFeeEarned(numPublications, numDelayedPublications));
    }

    /// @inheritdoc IProverManager
    function finalizePastPeriod(uint256 periodId, IPublicationFeed.PublicationHeader calldata provenPublication)
        external
    {
        require(publicationFeed.validateHeader(provenPublication), "Invalid publication header");

        ICheckpointTracker.Checkpoint memory lastProven = checkpointTracker.getProvenCheckpoint();
        require(lastProven.publicationId >= provenPublication.id, "Publication must be proven");

        LibProvingPeriod.Period storage period = _periods[periodId];
        require(period.isInitialized(), "Period not initialized");
        require(period.isBefore(provenPublication.timestamp), "Publication must be after period");

        _increaseBalance(period.prover, period.finalize(_rewardPercentage()));
    }

    /// @inheritdoc IProposerFees
    function getCurrentFees() external view returns (uint96 fee, uint96 delayedFee) {
        uint256 currentPeriod = _currentPeriodId;
        LibProvingPeriod.Period storage period = _periods[currentPeriod];

        if (period.isComplete()) {
            period = _periods[currentPeriod + 1];
        }

        fee = period.publicationFee(false);
        delayedFee = period.publicationFee(true);
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

    /// @dev Increases `user`'s balance by `amount` and emits a `Deposit` event
    function _deposit(address user, uint256 amount) internal {
        _increaseBalance(user, amount);
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
        LibProvingPeriod.Period storage nextPeriod = _periods[periodId + 1];

        require(period.isVacant(), "No proving vacancy");
        period.close(0, 0);

        _decreaseBalance(prover, _livenessBond());
        nextPeriod.init(prover, fee, _delayedFeePercentage(), _livenessBond());
    }

    /// @notice mark the next period as active. Future publications will be assigned to the new period
    function _advancePeriod() private returns (uint256 periodId) {
        _currentPeriodId++;
        periodId = _currentPeriodId;
        emit NewPeriod(periodId);
    }
}
