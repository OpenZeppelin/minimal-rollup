pragma solidity ^0.8.28;

import {BaseProverManager} from "./BaseProverManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title ERC20ProverManager
/// @notice Implementation of the `BaseProverManager` contract that uses an ERC20 decided by the deployer of this
/// contract for bids, stake and paying for publication fees.
abstract contract ERC20ProverManager is BaseProverManager {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;

    constructor(
        address _inbox,
        address _checkpointTracker,
        address _publicationFeed,
        address _initialProver,
        uint256 _initialFee,
        address _token
    ) payable BaseProverManager(_inbox, _checkpointTracker, _publicationFeed, _initialProver, _initialFee, msg.value) {
        require(_token != address(0), "Token address cannot be 0");

        token = IERC20(_token);

        // Deposit the amount of funds needed for the liveness bond from the deployer
        token.safeTransferFrom(msg.sender, address(this), _livenessBond());
    }

    /// @notice Deposit tokens into the contract. The deposit can be used both for opting in as a prover or proposer
    function deposit(uint256 amount) external {
        _deposit(msg.sender, amount);
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function _transferOut(address to, uint256 amount) internal override {
        token.safeTransfer(to, amount);
    }
}
