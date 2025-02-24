// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ProvingAuctionManager {
    // /// @dev Information about a period of publications.
    // struct Period {
    //     FeePool feePool;
    //     Auction auction;
    // }

    /// @dev Information about an accepted auction.
    struct Auction {
        uint256 deadline; // limit that the selected prover has to finalize the chain
        uint128 stake; // amount of stake the prover has committed to
        uint128 feePerPublication; // fee that the prover will charge per publication
        address prover; // prover that accepted
        bool finalized;
    }

    // TODO: can this be merged with Auction in a single larger struct called period?
    struct FeePool {
        uint128 totalFee;
        uint128 totalPublications;
        mapping(address proposer => uint128 fee) fees;
    }

    struct Balance {
        uint128 available;
        uint128 locked; // staked when opting in to prove a period
    }

    // Parameters for the auction and proving window
    /// @notice Duration (seconds) of each auction round.
    uint256 public auctionDuration;
    /// @notice Maximum reward per publication (if full period elapses).
    uint128 public maxFeePerPublication;
    /// @notice Time (seconds) allowed after acceptance to finalize.
    uint256 public finalizationDeadline;
    /// @notice Auction genesis timestamp (auctions are aligned relative to this).
    uint256 public auctionGenesis;

    /// @notice Global user balances.
    mapping(address user => Balance balance) public balances;
    /// @notice Auctions by Id.
    /// @dev The periodId is deterministic and determined by time.
    mapping(uint256 periodId => Auction auction) public auctions;
    /// @notice Keep track of fees paid by proposers for each period.
    mapping(uint256 periodId => FeePool feePool) public feePools;

    /// @notice Only the CheckpointTracker may call finalizeAuction.
    address public immutable checkpointTracker;

    /// @notice Emitted when a prover commits to prove a period.
    event ProverCommitted(
        uint256 indexed periodId, address indexed prover, uint256 deadline, uint256 stake, uint256 feePerPublication
    );
    /// @notice Emitted when a prover finalizes a period in time.
    event ProverFinalized(uint256 indexed periodId, address indexed prover, uint256 reward);
    /// @notice Emitted when a prover finalizes late and their stake is slashed.
    event ProverSlashed(
        uint256 indexed periodId, address indexed prover, uint256 slashedStake, address fallbackProver, uint256 reward
    );

    /// @param _checkpointTracker The CheckpointTracker contract address.
    /// @param _auctionDuration Duration of each auction round in seconds.
    /// @param _maxFeePerPublication Maximum reward per publication.
    /// @param _finalizationDeadline Time allowed to finalize after acceptance.
    /// @param _auctionGenesis Timestamp from which auctions are aligned.
    constructor(
        address _checkpointTracker,
        uint256 _auctionDuration,
        uint128 _maxFeePerPublication,
        uint256 _finalizationDeadline,
        uint256 _auctionGenesis
    ) {
        checkpointTracker = _checkpointTracker;
        auctionDuration = _auctionDuration;
        maxFeePerPublication = _maxFeePerPublication;
        finalizationDeadline = _finalizationDeadline;
        auctionGenesis = _auctionGenesis;
    }

    /// @notice Deposit ETH into your balance.
    function deposit() external payable {
        balances[msg.sender].available += uint128(msg.value);
    }

    /// @notice Withdraw available (unlocked) funds.
    function withdraw(uint128 amount) external {
        balances[msg.sender].available -= amount;

        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "Withdraw failed");
    }

    /// @notice Proposers pay for their publications. Funds go to the fee pool and credit their balance.
    // TODO: should we treat forced publications differently?
    // TODO: make this payable to allow just in time deposits
    function payForPublication() external {
        balances[msg.sender].available -= maxFeePerPublication;

        uint256 periodId = _getPeriodId(block.timestamp);
        feePools[periodId].totalFee += maxFeePerPublication;
        feePools[periodId].totalPublications++;
        feePools[periodId].fees[msg.sender] += maxFeePerPublication;
    }

    /// @notice Commits to prove a certain period.
    /// @param periodId The period you are committing to prove. It will usually be the current period, but in case no
    /// one opted in during that period, a prover can step in and use the `maxFeePerPublication`
    function commitToProve(uint256 periodId) external {
        require(block.timestamp >= auctionGenesis, "Auctions not started yet");
        require(auctions[periodId].prover == address(0), "Period already has an elected prover");

        uint256 periodStart = auctionGenesis + periodId * auctionDuration;
        uint256 elapsed = block.timestamp - periodStart;
        if (elapsed > auctionDuration) {
            // We are participating in an old period.
            elapsed = auctionDuration;
        }

        // Calculate the price per publication for the period.
        uint128 feePerPublication = uint128((maxFeePerPublication * elapsed) / auctionDuration);

        // We ask the prover to stake at least the total reward for the period.
        uint128 stake = feePools[periodId].totalFee;
        Balance storage balance = balances[msg.sender];
        balance.available -= stake;
        balance.locked += stake;

        auctions[periodId] = Auction({
            deadline: block.timestamp + finalizationDeadline,
            stake: stake,
            feePerPublication: feePerPublication,
            prover: msg.sender,
            finalized: false
        });

        emit ProverCommitted(periodId, msg.sender, block.timestamp + finalizationDeadline, stake, feePerPublication);
    }

    /// @notice Finalizes a prover's commitment to prove a period. Can only be called when advancing the chain's tail.
    /// @dev Called by the CheckpointTracker. If finalized on time, the accepted prover’s reward is credited;
    /// if late, the fallback caller receives the locked funds (and the accepted prover is slashed).
    /// @param periodId The period ID.
    /// @param caller The address calling finalization (could be the accepted prover or a fallback).
    function finalizeCommitment(uint256 periodId, address caller) external {
        require(msg.sender == checkpointTracker, "Only CheckpointTracker");

        Auction storage auction = auctions[periodId];

        address prover = auction.prover;
        require(prover != address(0), "Period not committed");
        require(!auction.finalized, "Period already proven");

        uint128 publicationFees = auction.feePerPublication * feePools[periodId].totalPublications;
        if (block.timestamp <= auction.deadline) {
            // On-time: the designated prover earns the publications' fees and can withdraw their stake.
            Balance storage balance = balances[prover];
            balance.available += auction.stake + publicationFees;
            balance.locked -= auction.stake;

            // TODO: how do we allow the proposers to withdraw the remaining balance(maxFeePerPublication - actualFee)?
            emit ProverFinalized(periodId, prover, publicationFees);
        } else {
            // Late: fallback finalizes. Slash the accepted prover.
            uint128 stake = auction.stake;
            balances[prover].locked -= stake;

            // Give the publications' fees to whoever proves the period.
            //TODO: we probably shouldn't give all the stake to the caller, only a part of it and burn the rest or send
            // it to the treasury
            balances[caller].available += publicationFees + stake;

            emit ProverSlashed(periodId, prover, stake, caller, publicationFees);
        }

        auction.finalized = true;
    }

    function _getPeriodId(uint256 timestamp) internal view returns (uint256) {
        require(timestamp >= auctionGenesis, "Auction not started yet");
        return (timestamp - auctionGenesis) / auctionDuration;
    }

    receive() external payable {
        balances[msg.sender].available += uint128(msg.value);
    }
}
