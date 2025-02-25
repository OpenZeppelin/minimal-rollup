// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "../ICheckpointTracker.sol";
import {IProverManager} from "../IProverManager.sol";
import {IPublicationFeed} from "../IPublicationFeed.sol";
import {IProposerFees} from "../IProposerFees.sol";
import {IProverManager} from "../IProverManager.sol";

contract ProverManager is IProposerFees, IProverManager{
    struct Period {
        address prover;
        uint256 livenessBond; // stake the prover has to pay to register
        uint256 accumulatedFees; // the fees accumulated by proposers' publications for this period
        uint256 fee; // per-publication fee (in wei)
        uint256 exitAllowedAt; //the time when the prover will be evicted
        uint256 deadline; // the time by which the prover needs to submit a proof(this is only needed after a prover exits or is replaced)
        bool slashed; //  flag that signlas the prover should be slashed(they have been evicted)
    }

    address public immutable inbox;
    ICheckpointTracker public immutable checkpointTracker;
    IPublicationFeed public immutable publicationFeed;

    // -- Configuration parameters --
    /// @notice The minimum percentage by which the prover's fee must be lower than the current prover's fee
    /// @dev This is used to prevent gas wars where the new prover undercuts the current prover by just a few wei
    uint256 public minStepPercentage;
    /// @notice The time window after which a publication is considered old and the prover can be evicted
    uint256 public oldPublicationWindow;
    /// @notice The delay after which the pending prover can become active
    uint256 public offerActivationDelay;
    /// @notice The delay after which the current prover can exit
    uint256 public exitDelay;
    /// @notice The delay after which the current prover is evicted if they are inactive
    /// @dev This cannot happen immediately to allow other provers to bid for the role
    uint256 public innactiveExitDelay;
    /// @notice The multiplier for delayed publications
    uint256 public delayedFeeMultiplier;
    ///@notice The deadline for a prover to submit a valid proof after their period ends
    uint256 public provingDeadline;
    /// @notice The minimum stake required to be a prover
    /// @dev This should be enough to cover the cost of a new prover if the current prover becomes innactive
    uint256 public livenessBond;
    /// @notice The percentage of the liveness bond that the evictor gets as an incentive
    uint256 public evictorIncentivePercentage;
    /// @notice The percentage of the liveness bond(at the moment of the slashing) that is burned when a prover is slashed
    uint256 public burnedStakePercentage;

    /// @notice Common balances for proposers and provers
    mapping(address => uint256) public balances;
    /// @notice Periods represent proving windows
    /// @dev Most of the time we are dealing with the current period or next period(bids for the next period),
    /// but we need periods in the past to track publications that still need to be proven after the prover is
    /// evicted(or exits)
    mapping(uint256 periodId => Period period) public periods;
    /// @notice The current period
    uint256 public currentPeriodId;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event ProverOffered(address indexed proposer, uint256 fee, uint256 stake);
    event ProverActivated(address indexed oldProver, address indexed newProver, uint256 fee);
    event ProverSlashed(address indexed prover, address indexed slasher, uint256 slashedAmount);
    event ProverEvicted(address indexed prover, address indexed evictor, uint256 exitAllowedAt, uint256 livenessBond);
    event ProverExited(address indexed prover, uint256 exitAllowedAt, uint256 provingDeadline);

    constructor(
        uint256 _minStepPercentage,
        uint256 _oldPublicationWindow,
        uint256 _offerActivationDelay,
        uint256 _exitDelay,
        uint256 _delayedFeeMultiplier,
        address _inbox,
        address _checkpointTracker,
        address _publicationFeed,
        uint256 _burnedStakePercentage
    ) {
        minStepPercentage = _minStepPercentage;
        oldPublicationWindow = _oldPublicationWindow;
        offerActivationDelay = _offerActivationDelay;
        exitDelay = _exitDelay;
        delayedFeeMultiplier = _delayedFeeMultiplier;
        burnedStakePercentage = _burnedStakePercentage;
        inbox = _inbox;
        checkpointTracker = ICheckpointTracker(_checkpointTracker);
        publicationFeed = IPublicationFeed(_publicationFeed);
    }

    /// @notice Deposit ETH into the contract. The deposit can be used both for opting in as a prover or proposer
    function deposit() external payable {
        balances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw available (unlocked) funds.
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
        uint256 currentPeriodExit = periods[currentPeriod].exitAllowedAt;

        if (block.timestamp > currentPeriodExit) {
            // Advance to the next period
            currentPeriodId++;
            currentPeriod++;
        }

        uint256 requiredFee = periods[currentPeriod].fee;
        //TODO: I'm not sure this is the corret way to deal with this
        if (isDelayed) {
            requiredFee *= delayedFeeMultiplier;
        }

        // Deduct fee from sender's balance and add to pendingFee
        balances[proposer] -= requiredFee;
        periods[currentPeriod].accumulatedFees += requiredFee;
    }

    /// @notice Register as a prover for the next period by offering to charge a fee at least `minStepPercentage` than
    /// the current best price.
    /// @dev The current best price may be the current prover's fee or the fee of the next bid, depending on a few
    /// conditions.
    /// @param offeredFee The fee you are willing to charge for proving each publication
    function registerProver(uint256 offeredFee) external {
        uint256 _livenessBond = livenessBond;
        require(balances[msg.sender] >= _livenessBond, "Insufficient balance for stake");

        uint256 currentPeriod = currentPeriodId;
        Period storage _currentPeriod = periods[currentPeriod];
        Period storage _nextPeriod = periods[currentPeriod + 1];
        uint256 currentFee = _currentPeriod.fee;
        uint256 nextFee = _nextPeriod.fee;
        uint256 requiredMaxFee;
        if (_currentPeriod.prover != address(0) && _currentPeriod.exitAllowedAt == 0) {
            // Only if there is a prover for the current period, and they have not been evicted yet we need to check if
            // the offer is below their's
            requiredMaxFee = currentFee - (currentFee * minStepPercentage / 100);
            require(offeredFee <= requiredMaxFee, "Offered fee not low enough");

            uint256 exitAllowedAt = block.timestamp + offerActivationDelay;
            _currentPeriod.exitAllowedAt = exitAllowedAt;
            _currentPeriod.deadline = exitAllowedAt + provingDeadline;
        }

        address _nextProverAddress = _nextPeriod.prover;
        if (_nextProverAddress != address(0)) {
            // If there's already a bid for the next period, we need to check if the offered fee is below that
            requiredMaxFee = nextFee - (nextFee * minStepPercentage / 100);
            require(offeredFee <= requiredMaxFee, "Offered fee not low enough");

            // Refund the liveness bond to the losing bid
            balances[_nextProverAddress] += _nextPeriod.livenessBond;
        }

        // Record the next period info
        _nextPeriod.prover = msg.sender;
        _nextPeriod.fee = offeredFee;
        _nextPeriod.livenessBond = _livenessBond;

        emit ProverOffered(msg.sender, offeredFee, _livenessBond);
    }

    /// @notice Evicts a prover that has been inactive opens up the prover role for registration.
    /// @dev This can be called by anyone, and they get a part of the liveness bond as a reward as an incentive.
    /// @param publicationId The publication id that the caller is claiming is too old and hasn't been proven
    function evictProver(uint256 publicationId, IPublicationFeed.PublicationHeader calldata publicationHeader)
        external
    {
        require(
            keccak256(abi.encode(publicationHeader)) == publicationFeed.getPublicationHash(publicationId),
            "Publication hash does not match"
        );

        uint256 publicationTimestamp = publicationHeader.timestamp;
        require(publicationTimestamp + oldPublicationWindow < block.timestamp, "Publication is not old enough");

        uint256 exitAllowedAt = block.timestamp + innactiveExitDelay;
        Period storage period = periods[currentPeriodId];
        period.slashed = true;
        period.exitAllowedAt = exitAllowedAt;

        // Reward the evictor
        uint256 evictorIncentive = period.livenessBond * evictorIncentivePercentage / 100;
        balances[msg.sender] += evictorIncentive;
        period.livenessBond -= evictorIncentive;

        emit ProverEvicted(period.prover, msg.sender, exitAllowedAt, period.livenessBond);
    }

    /// @notice The current prover can signal exit to eventually pull out their liveness bond.
    /// @dev They still have to wait for the `exitDelay` to allow other provers to bid for the role.
    /// @dev The prover is still on the hook to prove publications for the current period.
    function exit() external {
        Period storage period = periods[currentPeriodId];
        address _prover = period.prover;
        require(msg.sender == _prover, "Not current prover");
        require(period.exitAllowedAt == 0, "Prover already exited");

        uint256 exitAllowedAt = block.timestamp + exitDelay;
        uint256 _provingDeadline = exitAllowedAt + provingDeadline;
        period.exitAllowedAt = exitAllowedAt;
        period.deadline = _provingDeadline;

        emit ProverExited(_prover, exitAllowedAt, _provingDeadline);
    }

    /// @notice Called by a prover to submit a proof for a set of publications he is assigned to.
    /// @dev This only works if the prover is within their deadline.
    /// @dev If the prover has finished all their publications for the period, they can also claim the fees and the
    /// liveness bond.
    /// @param start The initial checkpoint before the transition
    /// @param end The final checkpoint after the transition
    /// @param nextPublicationHeaderBytes Optional parameter that should only be sent when the prover has finished all
    /// their publications for the period.
    /// @param proof Arbitrary data passed to the `verifier` contract to confirm the transition validity
    /// @param periodId The id of the period for which the proof is submitted
    function proveOwnPeriod(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader calldata endPublicationHeader,
        bytes calldata nextPublicationHeaderBytes,
        bytes calldata proof,
        uint256 periodId
    ) external {
        Period storage period = periods[periodId];
        if (period.deadline != 0) {
            // This means that there is a deadline for the prover, we have to make sure they are within that deadline
            require(block.timestamp <= period.deadline, "Deadline has passed");
        }

        // Verify that the end publication is within the period and valid
        uint256 periodEnd = period.exitAllowedAt;
        require(keccak256(abi.encode(endPublicationHeader)) == publicationFeed.getPublicationHash(end.publicationId), "Publication hash does not match");
        require(endPublicationHeader.id == end.publicationId, "This is not the end publication");
        require(endPublicationHeader.timestamp < periodEnd, "End publication is not within the period");

        checkpointTracker.proveTransition(start, end, proof);

        if (nextPublicationHeaderBytes.length > 0) {
            // This means that the prover is claiming that they have finished all their publications for the period
            IPublicationFeed.PublicationHeader memory nextPublicationHeader =
                abi.decode(nextPublicationHeaderBytes, (IPublicationFeed.PublicationHeader));
            require(nextPublicationHeader.id == end.publicationId + 1, "This is not the next publication");
            require(nextPublicationHeader.timestamp > periodEnd, "Next publication is not after the period end");
            require(
                keccak256(abi.encode(nextPublicationHeader))
                    == publicationFeed.getPublicationHash(nextPublicationHeader.id),
                "Publication hash does not match"
            );

            // If they have finished all their publications for the period, distribute the funds to the prover
            balances[period.prover] += period.accumulatedFees + period.livenessBond;
            delete periods[periodId];
        }
    }

    /// @inheritdoc IProverManager
    function proveOtherPeriod(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader[] calldata publicationHeadersToProve, // these are the rollup's publications
        IPublicationFeed.PublicationHeader calldata nextPublicationHeader,
        bytes calldata proof,
        uint256 periodId
    ) external {
        Period storage period = periods[periodId];
        uint256 numPubs = publicationHeadersToProve.length;
        IPublicationFeed.PublicationHeader memory endPublicationHeader = publicationHeadersToProve[numPubs - 1];

        require(period.slashed || block.timestamp > period.deadline, "We are still within the proving period");

        //TODO: Should we check that the first publication is after the period start?
       // Verify that the end publication is within the period and valid
        uint256 periodEnd = period.exitAllowedAt;
        require(keccak256(abi.encode(endPublicationHeader)) == publicationFeed.getPublicationHash(end.publicationId), "Publication hash does not match");
        require(endPublicationHeader.id == end.publicationId, "This is not the end publication");
        require(endPublicationHeader.timestamp < periodEnd, "End publication is not within the period");

        // Verify that the next publication is valid and after the period end
        require(nextPublicationHeader.id == end.publicationId + 1, "This is not the next publication");
        require(nextPublicationHeader.timestamp > periodEnd, "Next publication is not after the period end");
        require(
            keccak256(abi.encode(nextPublicationHeader))
                == publicationFeed.getPublicationHash(nextPublicationHeader.id),
            "Publication hash does not match"
        );

        //Verify that all the publications are correct and linked together(they belong to this rollup)
        for (uint256 i = 0; i < numPubs; i++) {
            require(keccak256(abi.encode(publicationHeadersToProve[i])) == publicationFeed.getPublicationHash(publicationHeadersToProve[i].id), "Publication hash does not match");
            if (i > 0) {
                bytes32 prevHash = keccak256(abi.encode(publicationHeadersToProve[i-1]));
                require(prevHash == publicationHeadersToProve[i].prevHash, "Previous publication hash does not match");
            }
        }

        checkpointTracker.proveTransition(start, end, proof);

        // Distribute the funds
        uint256 _livenessBond = period.livenessBond;
        uint256 accumulatedFees = period.accumulatedFees;
        uint256 newProverFees = period.fee * numPubs;

        // Pay the designed prover for the work they already did
        balances[period.prover] += accumulatedFees - newProverFees;
        
        // Compensate the new prover(fees for the set of publications + a portion of the liveness bond)
        uint256 livenessBondReward = _livenessBond * (100 - burnedStakePercentage) / 100;
        balances[msg.sender] += newProverFees + livenessBondReward;

        // Delete the period. This implicitely burns the remaining part of the liveness bond
        delete periods[periodId];
        
    }
}
