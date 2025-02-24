// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Checkpoint} from "../Checkpoint.sol";
import {IProverManager} from "../IProverManager.sol";

contract ProverManager is IProverManager {
    struct ProverInfo {
        address prover;
        uint256 stake;
        uint256 fee; // per-publication fee (in wei)
        uint256 exitAllowedAt;
    }

    // ----------------------------------------------------------
    // Configuration parameters
    // ----------------------------------------------------------

    uint256 public minStepFee;
    uint256 public maxUnprovenPublications;
    uint256 public offerActivationDelay;
    uint256 public exitDelay;
    uint256 public forcedFeeMultiplier;
    // TODO: this should actually be dynamic, most likely using the latest proven fee
    uint256 public minStake;

    // ----------------------------------------------------------
    // Balances and Prover Info
    // ----------------------------------------------------------
    /// @notice Balances for proposers and provers
    mapping(address => uint256) public balances;

    ProverInfo public currentProverInfo;

    // Pending prover info (if someone is trying to undercut)
    ProverInfo public pendingProverInfo;
    uint256 public pendingActivationTime;

    uint256 public pendingFee;

    uint256 public lastProvenPublicationId;

    Checkpoint public immutable checkpoint;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event ProverOffered(address indexed proposer, uint256 fee, uint256 stake);
    event ProverActivated(address indexed oldProver, address indexed newProver, uint256 fee);
    event ProverSlashed(address indexed prover, uint256 slashedAmount);

    constructor(
        address _checkpoint,
        uint256 _minStepFee,
        uint256 _maxUnprovenPublications,
        uint256 _offerActivationDelay,
        uint256 _exitDelay,
        uint256 _forcedFeeMultiplier
    ) {
        minStepFee = _minStepFee;
        maxUnprovenPublications = _maxUnprovenPublications;
        offerActivationDelay = _offerActivationDelay;
        exitDelay = _exitDelay;
        forcedFeeMultiplier = _forcedFeeMultiplier;

        checkpoint = Checkpoint(_checkpoint);
        currentProverInfo.fee = type(uint256).max;
        lastProvenPublicationId = checkpoint.publicationId();
    }

    /// @notice Deposit ETH into the prover manager. The deposit can be used both for opting in as a prover or proposer
    function deposit() external payable {
        require(msg.value > 0, "No ETH sent");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
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
        // Publication fee applies to the publication with ID = lastProvenPublicationId + 1.
        uint256 requiredFee = currentProverInfo.fee;
        if (isForced) {
            requiredFee = currentProverInfo.fee * forcedFeeMultiplier;
        }
        require(balances[msg.sender] >= requiredFee, "Insufficient balance to pay fee");

        // Deduct fee from sender's balance and add to pendingFee
        balances[msg.sender] -= requiredFee;
        pendingFee += requiredFee;
    }

    /// @notice Register yourself as a prover
    /// @param offeredFee The fee you are willing to charge for proving each publication
    function offerProverRole(uint256 offeredFee) external payable {
        uint256 stake = msg.value;
        require(offeredFee <= currentProverInfo.fee - minStepFee, "Fee not low enough");
        require(stake >= minStake, "Must provide enough stake");

        // Record pending prover info
        pendingProverInfo = ProverInfo({prover: msg.sender, stake: stake, fee: offeredFee, exitAllowedAt: 0});
        pendingActivationTime = block.timestamp + offerActivationDelay;
        emit ProverOffered(msg.sender, offeredFee, stake);
    }

    /// @notice Activates the pending prover. Anyone can call this function to prevent the pending prover to opt out if
    /// the price is not convinient for the.
    function activateProver() external {
        require(msg.sender == pendingProverInfo.prover, "Not pending prover");
        require(block.timestamp >= pendingActivationTime, "Activation delay not passed");

        uint256 latestPub = checkpoint.publicationId();
        // If the current prover is too far behind, slash their stake.
        if (currentProverInfo.prover != address(0) && latestPub > lastProvenPublicationId + maxUnprovenPublications) {
            uint256 slashed = currentProverInfo.stake;
            // Reward the new prover with the slashed amount.
            balances[pendingProverInfo.prover] += slashed;
            emit ProverSlashed(currentProverInfo.prover, slashed);
        } else if (currentProverInfo.prover != address(0)) {
            // Otherwise, simply credit the current prover's stake back to them.
            balances[currentProverInfo.prover] += currentProverInfo.stake;
        }
        // Update current prover info with the pending prover's info.
        address oldProver = currentProverInfo.prover;
        currentProverInfo = pendingProverInfo;
        // Reset pending info
        delete pendingProverInfo;
        pendingActivationTime = 0;
        emit ProverActivated(oldProver, currentProverInfo.prover, currentProverInfo.fee);
    }

    /**
     * @notice The current prover can signal exit to eventually pull out their stake.
     */
    function signalExit() external {
        require(msg.sender == currentProverInfo.prover, "Not current prover");
        require(currentProverInfo.exitAllowedAt == 0, "Exit already signaled");
        currentProverInfo.exitAllowedAt = block.timestamp + exitDelay;
    }

    /**
     * @notice After the exit delay, the current prover can pull out their stake.
     */
    function pullStake() external {
        require(msg.sender == currentProverInfo.prover, "Not current prover");
        require(
            currentProverInfo.exitAllowedAt != 0 && block.timestamp >= currentProverInfo.exitAllowedAt,
            "Exit delay not passed"
        );
        uint256 amount = currentProverInfo.stake;
        currentProverInfo.stake = 0;
        // Instead of sending funds, we add them to the prover's balance (pull pattern).
        balances[msg.sender] += amount;
    }

    // ----------------------------------------------------------
    // IProverIncentives Implementation
    // ----------------------------------------------------------
    /**
     * @notice Only the current designated prover can prove a publication,
     *         and the publication must be newer than the last proven.
     */
    function canProve(address prover, uint256, /*startId*/ uint256 endId) external view returns (bool) {
        if (prover == currentProverInfo.prover && endId > lastProvenPublicationId) {
            return true;
        }
        return false;
    }

    /**
     * @notice Called by the Checkpoint contract when a publication is proven.
     *         The pendingFee is added to the current prover's balance, and lastProvenPublicationId updated.
     */
    function onProven(address prover, uint256, /*startId*/ uint256 endId) external {
        require(prover == currentProverInfo.prover, "Prover mismatch");

        // Release the pending fee to the prover.
        balances[prover] += pendingFee;
        pendingFee = 0;
        lastProvenPublicationId = endId;
    }
}
