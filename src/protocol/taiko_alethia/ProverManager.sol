// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Checkpoint} from "../Checkpoint.sol";
import {IProverManager} from "../IProverManager.sol";

/**
 * @title SimplifiedProverIncentiveManager
 * @notice A simplified version that:
 *   - Uses one mapping (balances) for all funds.
 *   - Accepts publication fees only for the next publication (sequential processing).
 *   - Tracks the pending publication fee in a single variable.
 *   - Includes basic prover bidding and activation logic.
 *
 * Note: This simplified version assumes that publication fees are deposited for publication ID
 *       = lastProvenPublicationId + 1. More complex fee management requires a mapping.
 */
contract ProverManager is IProverManager {
    // ----------------------------------------------------------
    // Configuration parameters
    // ----------------------------------------------------------
    uint256 public constant MIN_FEE_STEP = 1 wei;
    uint256 public maxUnprovenPublications = 10;
    uint256 public offerActivationDelay = 1 hours;
    uint256 public exitDelay = 1 hours;
    uint256 public forcedFeeMultiplier = 2;

    // ----------------------------------------------------------
    // External contract reference
    // ----------------------------------------------------------
    Checkpoint public immutable checkpoint;

    // ----------------------------------------------------------
    // Global balances mapping (for publishers, provers, etc.)
    // ----------------------------------------------------------
    mapping(address => uint256) public balances;

    // ----------------------------------------------------------
    // Prover state (packed into a struct for potential storage savings)
    // ----------------------------------------------------------
    struct ProverInfo {
        address prover;
        uint256 stake;
        uint256 fee; // per-publication fee (in wei)
        uint256 exitAllowedAt;
    }

    ProverInfo public currentProverInfo;

    // Pending prover info (if someone is trying to undercut)
    ProverInfo public pendingProverInfo;
    uint256 public pendingActivationTime; // when the pending prover can activate

    // ----------------------------------------------------------
    // Publication fee tracking
    // ----------------------------------------------------------
    // Instead of a mapping keyed by publication ID, we assume sequential publications.
    // The pendingFee is the total fee (from one or multiple publishers) for the publication
    // with ID = lastProvenPublicationId + 1.
    uint256 public pendingFee;

    // We track the last proven publication ID (should match Checkpoint.publicationId)
    uint256 public lastProvenPublicationId;

    // ----------------------------------------------------------
    // Events
    // ----------------------------------------------------------
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event PublicationFeePaid(address indexed publisher, uint256 feeAmount);
    event ProverOffered(address indexed proposer, uint256 fee, uint256 stake);
    event ProverActivated(address indexed oldProver, address indexed newProver, uint256 fee);
    event ProverSlashed(address indexed prover, uint256 slashedAmount);

    // ----------------------------------------------------------
    // Constructor
    // ----------------------------------------------------------
    constructor(address _checkpoint) {
        checkpoint = Checkpoint(_checkpoint);
        // Initialize current prover fee to a very high value (i.e. "infinite")
        currentProverInfo.fee = type(uint256).max;
        lastProvenPublicationId = checkpoint.publicationId();
    }

    // ----------------------------------------------------------
    // Deposit & Withdrawal (General Balance)
    // ----------------------------------------------------------
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

    // ----------------------------------------------------------
    // Publisher Fee Payment for the Next Publication
    // ----------------------------------------------------------
    /**
     * @notice Publishers pay fees for the next publication (must be sequential).
     *         They can top up by sending ETH along with the call.
     */
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
        emit PublicationFeePaid(msg.sender, requiredFee);
    }

    // ----------------------------------------------------------
    // Prover Bidding & Activation
    // ----------------------------------------------------------
    /**
     * @notice A new prover offers to take over by undercutting the current fee.
     *         They must lock up a stake by sending ETH.
     */
    function offerProverRole(uint256 offeredFee) external payable {
        require(offeredFee + MIN_FEE_STEP <= currentProverInfo.fee, "Fee not low enough");
        require(msg.value > 0, "Must provide stake");
        // Record pending prover info
        pendingProverInfo = ProverInfo({prover: msg.sender, stake: msg.value, fee: offeredFee, exitAllowedAt: 0});
        pendingActivationTime = block.timestamp + offerActivationDelay;
        emit ProverOffered(msg.sender, offeredFee, msg.value);
    }

    /**
     * @notice After the activation delay, the pending prover can activate.
     *         If the current prover is lagging (i.e. has too many unproven publications), they get slashed.
     */
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
        // Instead of sending funds, we add them to the prover’s balance (pull pattern).
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
     *         The pendingFee is added to the current prover’s balance, and lastProvenPublicationId updated.
     */
    function onProven(address prover, uint256, /*startId*/ uint256 endId) external {
        require(prover == currentProverInfo.prover, "Prover mismatch");

        // Release the pending fee to the prover.
        balances[prover] += pendingFee;
        pendingFee = 0;
        lastProvenPublicationId = endId;
    }
}
