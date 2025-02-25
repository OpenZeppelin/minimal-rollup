// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Checkpoint} from "../Checkpoint.sol";
import {IProverManager} from "../IProverManager.sol";

contract ProverManager {
    // struct ProverInfo {
    //     address prover;
    //     uint256 livenessBond; // stake the prover has to pay to register
    //     uint256 fee; // per-publication fee (in wei)
    //     uint256 accumulatedFees; // fees accumulated by proposers' publications
    //     uint256 exitAllowedAt; //the time when the prover will be evicted
    //     bool slashed; //  flag that signlas the prover should be slashed
    // }

    struct Period {
        address prover;
        uint256 livenessBond; // stake the prover has to pay to register
        uint256 accumulatedFees; // the fees accumulated by proposers' publications for this period
        uint256 fee; // per-publication fee (in wei)
        uint256 exitAllowedAt; //the time when the prover will be evicted
        uint256 deadline; // the time by which the prover needs to submit a proof(this should only be needed after eviction)
        bool slashed; //  flag that signlas the prover should be slashed
    }

    // -- Configuration parameters --
    /// @notice The minimum percentage by which the prover's fee must be lower than the current prover's fee
    /// @dev This is used to prevent gas wars where the new prover undercuts the current prover by just a few wei
    uint256 public minStepPercentage;
    /// @notice The maximum number of publications that can go unproven before the prover is slashed
    uint256 public maxUnprovenPublications;
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

    /// @notice Common balances for proposers and provers
    mapping(address => uint256) public balances;
    /// @notice Periods represent proving windows
    /// @dev Most of the time we are dealing with the current period or next period(bids for the next period), 
    /// but we need periods in the past to track publications that still need to be proven after the prover is evicted
    mapping(uint256 periodId => Period period) public periods;
    /// @notice The current period
    uint256 public currentPeriodId;


    // /// @notice The current prover
    // ProverInfo public currentProver;
    // /// @notice The next prover
    // ProverInfo public nextProver;

    uint256 public lastProvenPublicationId;
    address public inbox;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event ProverOffered(address indexed proposer, uint256 fee, uint256 stake);
    event ProverActivated(address indexed oldProver, address indexed newProver, uint256 fee);
    event ProverSlashed(address indexed prover, address indexed slasher, uint256 slashedAmount);
    event ProverEvicted(address indexed prover, address indexed evictor, uint256 exitAllowedAt, uint256 livenessBond);
    event ProverExited(address indexed prover, uint256 exitAllowedAt, uint256 provingDeadline);

    constructor(
        uint256 _minStepPercentage,
        uint256 _maxUnprovenPublications,
        uint256 _offerActivationDelay,
        uint256 _exitDelay,
        uint256 _delayedFeeMultiplier,
        address _inbox
    ) {
        minStepPercentage = _minStepPercentage;
        maxUnprovenPublications = _maxUnprovenPublications;
        offerActivationDelay = _offerActivationDelay;
        exitDelay = _exitDelay;
        delayedFeeMultiplier = _delayedFeeMultiplier;
        inbox = _inbox;
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

    /// @notice Proposers have to pay a fee for each publication they want to get proven. This should be called only by the Inbox contract.
    /// @dev This function advances to the next period if the current period has ended.
    /// @param isForced Whether the publication is a forced publication
    function payPublicationFee(address proposer, bool isForced) external payable {
        require(msg.sender == inbox, "Only the Inbox contract can call this function");

        // Accept additional deposit if sent
        if (msg.value > 0) {
            balances[proposer] += msg.value;
            emit Deposit(proposer, msg.value);
        }

        uint256 currentPeriod = currentPeriodId;
        uint256 currentPeriodExit = periods[currentPeriod].exitAllowedAt;

        if(block.timestamp > currentPeriodExit){
            // Advance to the next period
            currentPeriodId++;
            currentPeriod++;
        }

        uint256 requiredFee = periods[currentPeriod].fee;
        //TODO: I'm not sure this is the corret way to deal with this
        if (isForced) {
            requiredFee *= delayedFeeMultiplier;
        }

        // Deduct fee from sender's balance and add to pendingFee
        balances[proposer] -= requiredFee;
        periods[currentPeriod].accumulatedFees += requiredFee;
    }

    /// @notice Register as a prover for the next period by offering to charge a fee at least `minStepPercentage` than the current best price.
    /// @dev The current best price may be the current prover's fee or the fee of the next bid, depending on a few conditions.
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
            // Only if there is a prover for the current period, and they have not been evicted yet we need to check if the offer is below their's
            requiredMaxFee = currentFee - (currentFee * minStepPercentage / 100);
            require(offeredFee <= requiredMaxFee, "Offered fee not low enough");

            _currentPeriod.exitAllowedAt = block.timestamp + offerActivationDelay;
            _currentPeriod.deadline = _currentPeriod.exitAllowedAt + provingDeadline;
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

    /// @notice Activates the next prover. Anyone can call this function to prevent the pending prover to opt out if
    /// the price stops being convinient for them.
    /// @dev If the current prover was marked for slashing, the new prover will receive the slashed amount.
    function activateProver() external {
        address _currentProver = currentProver.prover;
        address _nextProver = nextProver.prover;
        require(block.timestamp >= currentProver.exitAllowedAt, "Cannot activate prover yet");
        require(_nextProver != address(0), "No pending prover");

        // slash the current prover if they were marked for slashing
        if (currentProver.slashed) {
            uint256 slashedAmount = currentProver.livenessBond;
            currentProver.livenessBond = 0;
            // TODO: Define how we distribute the slashed amount. For now for simplicity we just send it all to the next prover
            balances[_nextProver] += slashedAmount;

            emit ProverSlashed(_currentProver, msg.sender, slashedAmount);
        }
        else {
            // return the liveness bond to the current prover
            // TODO: This is not when we should give them their bond back. They still should prove their period
            balances[_currentProver] += currentProver.livenessBond;
        }

        // update the current prover
        currentProver = nextProver;
        delete nextProver;

        emit ProverActivated(_currentProver, _nextProver, currentProver.fee);
    }

    /// @notice Evicts a prover that has been inactive for `maxUnprovenPublications` publications and opens up the prover role for registration.
    /// @dev This can be called by anyone, but the slashing only happens when the remaining publications are proven.
    function evictProver() external {
        uint256 lastProvenPub = lastProvenPublicationId;
        // TODO: get the last published publication for this particular rollup and decide how we actually count the number of publications in between
        // Maybe an innactivity time window is just easier
        uint256 lastPub = 0;
        uint256 exitAllowedAt = block.timestamp + innactiveExitDelay;
        Period storage period = periods[currentPeriodId];
        if (lastPub - lastProvenPub > maxUnprovenPublications) {
            // Evict the prover
            period.slashed = true;
            period.exitAllowedAt = exitAllowedAt;
        }

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

    // /// @notice After the exit delay, the current prover can pull out their stake.
    // /// @dev They should also have proven all their publications by then.
    // function pullStake() external {
    //     require(msg.sender == currentProver.prover, "Not current prover");
    //     require(
    //         currentProver.exitAllowedAt != 0 && block.timestamp >= currentProver.exitAllowedAt,
    //         "Exit delay not passed"
    //     );
    //     uint256 amount = currentProver.livenessBond;
    //     currentProver.livenessBond = 0;
    //     // Instead of sending funds, we add them to the prover's balance (pull pattern).
    //     balances[msg.sender] += amount;
    // }

    // ----------------------------------------------------------
    // IProverIncentives Implementation
    // ----------------------------------------------------------
    // /// @notice Only the current designated prover can prove a publication,
    // ///         and the publication must be newer than the last proven.
    // function canProve(address prover, uint256, /*startId*/ uint256 endId) external view returns (bool) {
    //     if (prover == currentProver.prover && endId > lastProvenPublicationId) {
    //         return true;
    //     }
    //     return false;
    // }

    /// @notice Called by the Checkpoint contract when a publication is proven.
    /// @dev This function rewards the assigned prover if they are within their deadline, 
    /// and if they have finished all their publications for a period also returns their stake.
    /// @dev If the period has a slashed prover, then proving is permisionless and whoever can submit a proof first gets the reward plus the slashed amount.
    /// @dev If the proof is for a period that is beyond the deadline, then proving is also permisionless with the same conditions as above.
    // TODO: Once #42 is merged, use the new CheckPointTracker signature
    function onProven(uint256 end, bytes32 newCheckpoint, bytes calldata proof) external {
        
    }
}
