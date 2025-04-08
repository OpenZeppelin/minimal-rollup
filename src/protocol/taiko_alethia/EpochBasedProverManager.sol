// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "../ICheckpointTracker.sol";
import {IProposerFees} from "../IProposerFees.sol";
import {IProverManager} from "../IProverManager.sol";
import {IPublicationFeed} from "../IPublicationFeed.sol";

/**
 * @title EpochBasedProverManager
 * @notice Implementation of the epoch-based prover market design
 */
contract EpochBasedProverManager is IProposerFees, IProverManager {
    // Define auction states as an enum for better readability
    enum AuctionState {
        Pending, // 0 : No prover bids received yet
        Ongoing, // 1 : At least one bid received, bidding still open
        Concluded // 2 : Auction has ended, winning prover determined

    }

    struct Epoch {
        // Auction state
        AuctionState state;
        uint256 firstBidTimestamp; // When the first bid was placed
        uint256 winningBid; // The lowest bid amount (fee per publication)
        address winningProver; // The prover who placed the winning bid
        uint256 livenessBond; // Amount of ETH locked by the winning prover
        // Proving state
        uint256 auctionEndTimestamp; // When the auction concluded
        uint256 provingDeadline; // Deadline for proving all batches in this epoch
    }

    // -- Configuration parameters --
    uint256 public immutable epochSize; // Number of batches per epoch
    uint256 public immutable maxEpochLookahead; // A parameter determining how many epochs can be auctioned from the
        // current epoch
    uint256 public immutable auctionDuration; // Duration of auction from first bid
    uint256 public immutable provingWindowDuration; // Duration of proving window after auction ends
    uint256 public immutable requiredLivenessBond; // Minimum stake required to bid
    uint256 public immutable lateFeePercentage; // Percentage of liveness bond claimed by late prover (in bps)
    uint256 public immutable maxBidPercentage; // Maximum percentage for underbidding (in bps)

    address public immutable inbox;
    ICheckpointTracker public immutable checkpointTracker;
    IPublicationFeed public immutable publicationFeed;

    // -- State variables --
    mapping(address user => uint256 balance) public balances;
    mapping(uint256 epochId => Epoch) public epochs;
    uint256 public paidPublications;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event EpochBid(uint256 indexed epochId, address indexed prover, uint256 bidAmount);
    event AuctionStarted(uint256 indexed epochId, uint256 timestamp);
    event AuctionConcluded(uint256 indexed epochId, address indexed winner, uint256 winningBid);
    event PublicationProven(uint256 indexed publicationId, uint256 indexed epochId, address prover, bool afterDeadline);
    event LivenessBondReleased(uint256 indexed epochId, address indexed prover, uint256 amount);
    event LivenessBondSlashed(
        uint256 indexed epochId, address indexed winner, address indexed actualProver, uint256 amount
    );

    constructor(
        address _inbox,
        address _checkpointTracker,
        address _publicationFeed,
        uint256 _epochSize,
        uint256 _maxEpochLookahead,
        uint256 _auctionDuration,
        uint256 _provingWindowDuration,
        uint256 _requiredLivenessBond,
        uint256 _lateFeePercentage,
        uint256 _maxBidPercentage
    ) {
        inbox = _inbox;
        checkpointTracker = ICheckpointTracker(_checkpointTracker);
        publicationFeed = IPublicationFeed(_publicationFeed);

        epochSize = _epochSize;
        maxEpochLookahead = _maxEpochLookahead;
        auctionDuration = _auctionDuration;
        provingWindowDuration = _provingWindowDuration;
        requiredLivenessBond = _requiredLivenessBond;
        lateFeePercentage = _lateFeePercentage;
        maxBidPercentage = _maxBidPercentage;
    }

    /// @notice Deposit ETH into the contract
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw available(unlocked) funds
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;

        bool success;
        assembly ("memory-safe") {
            success := call(gas(), caller(), amount, 0, 0, 0, 0)
        }
        require(success, "Withdraw failed");

        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Place a bid for an epoch
    /// @param epochId The epoch to bid on. Can be calculated off-chain via: batchId mod 1024
    /// @param bidAmount The fee per publication offered
    /// @param success If bidding is successful or not. The reason we using boolen to indicate success (and not revert
    /// here) is, that in case of specific conditions, we need to conculde an auction, meaning we set the state
    /// accordingly.
    function bidForEpoch(uint256 epochId, uint256 bidAmount) public returns (bool success) {
        Epoch storage epoch = epochs[epochId];

        // Check if the epoch is eligible for bidding
        if (!_canStartAuction(epochId, epoch.firstBidTimestamp)) {
            return false;
        }

        // If this is the first bid, update the epoch state
        if (epoch.state == AuctionState.Pending) {
            epoch.state = AuctionState.Ongoing;
            epoch.firstBidTimestamp = block.timestamp;
            epoch.winningBid = bidAmount;
            epoch.winningProver = msg.sender;
            epoch.livenessBond = requiredLivenessBond;

            // Lock the prover's liveness bond - if has enough
            if (balances[msg.sender] < requiredLivenessBond) {
                return false;
            }

            balances[msg.sender] -= requiredLivenessBond;

            emit AuctionStarted(epochId, block.timestamp);

            return true;
        } else {
            // For subsequent bids, ensure the auction is still ongoing
            if (epoch.state != AuctionState.Ongoing) {
                return false;
            }

            // There is a case, where the auction (as a state) is not yet concluded, but time elapsed already, so
            // in such case we need to do that.
            if (block.timestamp > epoch.firstBidTimestamp + auctionDuration) {
                // Auction ended already, but not reflecting the state, so set status concluded.
                _concludeAuction(epochId);
                return false;
            }

            // Ensure the new bid is sufficiently lower than the current winning bid
            _ensureSufficientUnderbid(epoch.winningBid, bidAmount);

            // Return the previous winner's liveness bond
            balances[epoch.winningProver] += epoch.livenessBond;

            // Update the winning bid
            epoch.winningBid = bidAmount;
            epoch.winningProver = msg.sender;

            // Lock the new prover's liveness bond
            if(balances[msg.sender] < requiredLivenessBond) {
                return false;
            }
            balances[msg.sender] -= requiredLivenessBond;
        }

        emit EpochBid(epochId, msg.sender, bidAmount);
        return true;
    }

    /// @inheritdoc IProposerFees
    function payPublicationFee(address proposer, bool isDelayed) external {
        require(msg.sender == inbox, "Only the Inbox contract can call this function");

        // 1 publication is basically 1 batch. Paid per incoming.
        uint256 publicationId = paidPublications++;

        // Calculate which epoch this publication belongs to
        uint256 epochId = publicationId / epochSize;
        Epoch storage epoch = epochs[epochId];

        // Check if the epoch's auction has started
        require(epoch.state != AuctionState.Pending, "Epoch auction not started");
        require(epoch.winningBid != 0, "No current bid");

        // Determine fee based on whether the auction has concluded
        uint256 fee = epoch.winningBid;

        // Apply multiplier for delayed publications
        if (isDelayed) {
            fee = (fee * 12000) / 10000; // 120% of base fee for delayed publications
        }

        // Deduct fee from proposer's balance
        require(balances[proposer] >= fee, "Insufficient balance for publication fee");
        balances[proposer] -= fee;
    }

    /// @inheritdoc IProverManager
    function bid(uint256 offeredFee) external {
        // Get the last checkpoint to determine current publication ID
        ICheckpointTracker.Checkpoint memory lastCheckpoint = checkpointTracker.getLastCheckpoint();
        uint256 publicationId = lastCheckpoint.publicationId + 1;

        // Calculate which epoch this publication belongs to
        uint256 epochId = publicationId / epochSize;

        // Delegate to bidForEpoch
        bidForEpoch(epochId, offeredFee);
    }

    /// @inheritdoc IProverManager
    function evictProver(IPublicationFeed.PublicationHeader calldata publicationHeader) external {
        // Implementation not needed for the alternative design as it handles
        // prover inactivity differently through automatic slashing
        revert("Not implemented in epoch-based design");
    }

    /// @inheritdoc IProverManager
    function exit() external {
        // Implementation not needed for the alternative design
        revert("Not implemented in epoch-based design");
    }

    /// @inheritdoc IProverManager
    function claimProvingVacancy(uint256 fee) external {
        // Implementation not needed for the alternative design
        revert("Not implemented in epoch-based design");
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
        // Validate publication headers
        require(publicationFeed.validateHeader(firstPub), "Invalid first publication");
        require(publicationFeed.validateHeader(lastPub), "Invalid last publication");
        require(start.publicationId + 1 == firstPub.id, "First publication ID mismatch");
        require(end.publicationId == lastPub.id, "Last publication ID mismatch");

        // Calculate epoch for the publications
        uint256 firstEpochId = firstPub.id / epochSize;
        uint256 lastEpochId = lastPub.id / epochSize;

        // Ensure all publications are in the same epoch
        require(firstEpochId == lastEpochId, "Publications span multiple epochs");
        uint256 epochId = firstEpochId;

        Epoch storage epoch = epochs[epochId];

        // Determine if proof is being submitted after the deadline
        bool afterDeadline = false;

        if (epoch.state == AuctionState.Concluded) {
            if (epoch.provingDeadline != 0 && block.timestamp > epoch.provingDeadline) {
                afterDeadline = true;
            }
        }

        // Submit the proof to the checkpoint tracker
        checkpointTracker.proveTransition(start, end, numPublications, numDelayedPublications, proof);

        // Emit event for each proven publication
        for (uint256 i = firstPub.id; i <= lastPub.id; i++) {
            emit PublicationProven(i, epochId, msg.sender, afterDeadline);
        }

        // Handle rewards based on whether proof was submitted after deadline
        if (epoch.state == AuctionState.Concluded) {
            // Only settle if auction is concluded
            uint256 totalFee = numPublications * epoch.winningBid;

            if (afterDeadline) {
                // After deadline: actual prover gets part of the liveness bond, rest is burned
                if (msg.sender != epoch.winningProver) {
                    uint256 proverReward = (epoch.livenessBond * lateFeePercentage) / 10000;
                    balances[msg.sender] += proverReward;

                    // Mark the liveness bond as used (the rest is effectively burned)
                    epoch.livenessBond = 0;

                    emit LivenessBondSlashed(epochId, epoch.winningProver, msg.sender, proverReward);
                }
            } else {
                // Before deadline: winning prover gets the fee
                balances[epoch.winningProver] += totalFee;
            }
        }
    }

    /// @inheritdoc IProverManager
    function finalizePastPeriod(uint256 periodId, IPublicationFeed.PublicationHeader calldata provenPublication)
        external
    {
        // In this design, we use epochId instead of periodId
        uint256 epochId = periodId;
        Epoch storage epoch = epochs[epochId];

        require(epoch.state == AuctionState.Concluded, "Epoch auction not concluded");

        // Check if all publications in this epoch have been proven
        uint256 firstPublicationInEpoch = epochId * epochSize;
        uint256 lastPublicationInEpoch = firstPublicationInEpoch + epochSize - 1;

        ICheckpointTracker.Checkpoint memory lastProven = checkpointTracker.getProvenCheckpoint();

        // If the last proven publication is beyond this epoch, return the liveness bond
        if (lastProven.publicationId >= lastPublicationInEpoch && epoch.livenessBond > 0) {
            balances[epoch.winningProver] += epoch.livenessBond;

            uint256 bondReleased = epoch.livenessBond;
            epoch.livenessBond = 0;

            emit LivenessBondReleased(epochId, epoch.winningProver, bondReleased);
        }
    }

    /// @inheritdoc IProposerFees
    function getCurrentFees() external view returns (uint256 fee, uint256 delayedFee) {
        // Get the last checkpoint to determine current publication ID
        ICheckpointTracker.Checkpoint memory lastCheckpoint = checkpointTracker.getLastCheckpoint();
        uint256 publicationId = lastCheckpoint.publicationId + 1;

        // Calculate which epoch this publication belongs to
        uint256 epochId = publicationId / epochSize;
        Epoch storage epoch = epochs[epochId];

        // Determine fee based on epoch state
        if (epoch.state == AuctionState.Pending) {
            // Auction not started, return max uint as fee (effectively preventing publications)
            fee = type(uint256).max;
            delayedFee = type(uint256).max;
        } else if (epoch.state == AuctionState.Ongoing) {
            // Auction ongoing, use current winning bid
            fee = epoch.winningBid;
            delayedFee = (fee * 12000) / 10000; // 120% for delayed publications
        } else {
            // Auction concluded, use winning bid
            fee = epoch.winningBid;
            delayedFee = (fee * 12000) / 10000; // 120% for delayed publications
        }
    }

    /// @notice Check if an auction can be started for the given epoch
    /// @param epochIdToBid The epoch to check before auction start
    /// @param firstBidTs The first bid's timestamp per given epoch
    /// @return canStart True if an auction can be started for this epoch
    function _canStartAuction(uint256 epochIdToBid, uint256 firstBidTs) internal view returns (bool canStart) {
        // Ensure previous epoch has at least an ongoing auction
        if (epochIdToBid > 0 && epochs[epochIdToBid - 1].state == AuctionState.Pending) {
            return false;
        }

        // Check if this epoch's auction has already started or not
        if (epochs[epochIdToBid].state == AuctionState.Pending /* same as firstBidTs == 0 */ ) {
            uint256 currentEpochId = paidPublications % epochSize;
            if (epochIdToBid > currentEpochId + maxEpochLookahead) {
                // So if epoch is pending state, and within the lookahead window -> it can bid
                return true;
            }
        }

        // If ongoing, check if it is withing window
        if (epochs[epochIdToBid].state == AuctionState.Ongoing) {
            if (block.timestamp < firstBidTs + auctionDuration) {
                // So if epoch is ongoing state, and within the firstBidTs + some time 'T' window -> it can bid
                return true;
            }
        }

        return false;
    }

    /// @notice Internal function to conclude an auction
    /// @param epochId The epoch whose auction to conclude
    function _concludeAuction(uint256 epochId) internal {
        Epoch storage epoch = epochs[epochId];

        epoch.state = AuctionState.Concluded;
        epoch.auctionEndTimestamp = block.timestamp;
        epoch.provingDeadline = block.timestamp + provingWindowDuration;

        emit AuctionConcluded(epochId, epoch.winningProver, epoch.winningBid);
    }

    /// @dev Ensure the offered fee is low enough. It must be at most `maxBidPercentage` of the fee it is outbidding
    /// @param currentFee The fee to be outbid
    /// @param offeredFee The new bid
    function _ensureSufficientUnderbid(uint256 currentFee, uint256 offeredFee) private view {
        uint256 requiredMaxFee = (currentFee * maxBidPercentage) / 10000;
        require(offeredFee <= requiredMaxFee, "Offered fee not low enough");
    }

    /// @dev Calculates the percentage of a given amount
    /// @param amount The number to calculate the percentage of
    /// @param bps The percentage expressed in basis points
    /// @return result The calculated percentage of the given amount
    function _calculatePercentage(uint256 amount, uint256 bps) private pure returns (uint256 result) {
        return (amount * bps) / 10000;
    }
}
