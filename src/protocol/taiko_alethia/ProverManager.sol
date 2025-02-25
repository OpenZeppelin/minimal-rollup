// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Checkpoint} from "../Checkpoint.sol";
import {IProverManager} from "../IProverManager.sol";

contract ProverManager is IProverManager {
    struct ProverInfo {
        address prover;
        uint256 livenessBond; // stake the prover has to pay to register
        uint256 fee; // per-publication fee (in wei)
        uint256 accumulatedFees; // fees accumulated by proposers' publications
        uint256 exitAllowedAt; //the time when the prover will be evicted
        bool slashed; //  flag that signlas the prover should be slashed
    }

    // -- Configuration parameters --
    /// @notice The minimum percentage by which the prover's fee must be lower than the current prover's fee
    /// @dev This is used to prevent gas wars where the new prover undercuts the current prover by just a few wei
    uint256 public minStepPercentage;
    /// @notice The maximum number of publications that can go unproven before the prover is slashed
    uint256 public maxUnprovenPublications;
    /// @notice The delay after which the pending prover can activate
    uint256 public offerActivationDelay;
    /// @notice The delay after which the current prover can exit
    uint256 public exitDelay;
    /// @notice The delay after which the current prover is evicted if they are inactive
    /// @dev This cannot happen immediately to allow other provers to bid for the role
    uint256 public innactiveExitDelay;
    /// @notice The multiplier for delayed publications
    uint256 public delayedFeeMultiplier;
    /// @notice The minimum stake required to be a prover
    /// @dev This should be enough to cover the cost of a new prover if the current prover becomes innactive
    uint256 public livenessBond;

    /// @notice Balances for proposers and provers
    mapping(address => uint256) public balances;
    /// @notice The current prover
    ProverInfo public currentProver;
    /// @notice The next prover
    ProverInfo public nextProver;

    /// @notice The fees accumulated by proposers publishing. 
    /// @dev This can be claimed by the designated prover once they prove the appropiate publications
    uint256 public currentRewards;

    uint256 public lastProvenPublicationId;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event ProverOffered(address indexed proposer, uint256 fee, uint256 stake);
    event ProverActivated(address indexed oldProver, address indexed newProver, uint256 fee);
    event ProverSlashed(address indexed prover, address indexed slasher, uint256 slashedAmount);
    event ProverEvicted(address indexed prover, address indexed evictor, uint256 exitAllowedAt, uint256 livenessBond);
    constructor(
        uint256 _minStepPercentage,
        uint256 _maxUnprovenPublications,
        uint256 _offerActivationDelay,
        uint256 _exitDelay,
        uint256 _delayedFeeMultiplier
    ) {
        minStepPercentage = _minStepPercentage;
        maxUnprovenPublications = _maxUnprovenPublications;
        offerActivationDelay = _offerActivationDelay;
        exitDelay = _exitDelay;
        delayedFeeMultiplier = _delayedFeeMultiplier;
        currentProver.fee = type(uint256).max;
    }

    /// @notice Deposit ETH into the prover manager. The deposit can be used both for opting in as a prover or proposer
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

    /// @notice Proposers have to pay a fee for each publication they want to get proven.
    /// @param isForced Whether the publication is a forced publication
    function payPublicationFee(bool isForced) external payable {
        // Accept additional deposit if sent
        if (msg.value > 0) {
            balances[msg.sender] += msg.value;
            emit Deposit(msg.sender, msg.value);
        }

        uint256 requiredFee = currentProver.fee;
        if (isForced) {
            requiredFee *= delayedFeeMultiplier;
        }

        // Deduct fee from sender's balance and add to pendingFee
        balances[msg.sender] -= requiredFee;
        currentProver.accumulatedFees += requiredFee;
    }

    /// @notice Register as a prover by offering to charge a fee lower than the current prover's fee.
    /// @param offeredFee The fee you are willing to charge for proving each publication
    function registerProver(uint256 offeredFee) external {
        uint256 _livenessBond = livenessBond;
        require(balances[msg.sender] >= _livenessBond, "Insufficient balance for stake");

        // Ensure the offered fee is lower than the current prover's fee and any existing bid by at least `minStepPercentage`
        ProverInfo storage _currentProver = currentProver;
        ProverInfo storage _nextProver = nextProver;
        uint256 currentFee = _currentProver.fee;
        uint256 nextFee = _nextProver.fee;
        uint256 requiredMaxFee;
        if (_currentProver.prover != address(0)) {
            requiredMaxFee = currentFee - (currentFee * minStepPercentage / 100);
            require(offeredFee <= requiredMaxFee, "Offered fee not low enough");
        }

        if (_nextProver.prover != address(0)) {
            requiredMaxFee = nextFee - (nextFee * minStepPercentage / 100);
            require(offeredFee <= requiredMaxFee, "Offered fee not low enough");
        }

        // Record pending prover info
        _nextProver.prover = msg.sender;
        _nextProver.fee = offeredFee;
        _nextProver.livenessBond = _livenessBond;

        // If not set, register the time when the current prover will be deactivated
        if (_currentProver.exitAllowedAt == 0) {
            _currentProver.exitAllowedAt = block.timestamp + offerActivationDelay;
        }

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
    /// @dev This can be called by anyone, but the slashing only happens when the new prover activates.
    function evictProver() external {
        uint256 lastProvenPub = lastProvenPublicationId;
        // TODO: get the last published publication for this particular rollup
        uint256 lastPub = 0;
        uint256 allowedExitAt = block.timestamp + innactiveExitDelay;
        if (lastPub - lastProvenPub > maxUnprovenPublications) {
            // evict the prover
            currentProver.slashed = true;
            currentProver.exitAllowedAt = allowedExitAt;
        }

        emit ProverEvicted(currentProver.prover, msg.sender, allowedExitAt, currentProver.livenessBond);
    }

    /// @notice The current prover can signal exit to eventually pull out their liveness bond.
    /// @dev They still have to wait for the `exitDelay` to allow other provers to bid for the role.
    function exit() external {
        require(msg.sender == currentProver.prover, "Not current prover");
        require(currentProver.exitAllowedAt == 0, "Prover already exited");

        currentProver.exitAllowedAt = block.timestamp + exitDelay;
    }

    /// @notice After the exit delay, the current prover can pull out their stake.
    /// @dev They should also have proven all their publications by then.
    function pullStake() external {
        require(msg.sender == currentProver.prover, "Not current prover");
        require(
            currentProver.exitAllowedAt != 0 && block.timestamp >= currentProver.exitAllowedAt,
            "Exit delay not passed"
        );
        uint256 amount = currentProver.livenessBond;
        currentProver.livenessBond = 0;
        // Instead of sending funds, we add them to the prover's balance (pull pattern).
        balances[msg.sender] += amount;
    }

    // ----------------------------------------------------------
    // IProverIncentives Implementation
    // ----------------------------------------------------------
    /// @notice Only the current designated prover can prove a publication,
    ///         and the publication must be newer than the last proven.
    function canProve(address prover, uint256, /*startId*/ uint256 endId) external view returns (bool) {
        if (prover == currentProver.prover && endId > lastProvenPublicationId) {
            return true;
        }
        return false;
    }

    /// @notice Called by the Checkpoint contract when a publication is proven.
    ///         The pendingFee is added to the current prover's balance, and lastProvenPublicationId updated.
    function onProven(address prover, uint256 startId, uint256 endId) external {
        require(prover == currentProver.prover, "Prover mismatch");

        // Release the pending fee to the prover.
        balances[prover] += currentProver.accumulatedFees;
        currentProver.accumulatedFees = 0;
        lastProvenPublicationId = endId;
    }
}
