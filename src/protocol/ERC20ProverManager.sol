pragma solidity ^0.8.28;

import {BaseProverManager} from "./BaseProverManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title ERC20ProverManager
/// @notice Implementation of the `BaseProverManager` contract that uses an ERC20 decided by the deployer of this
/// contract for bids, stake and paying for publication fees.
/// @dev This contract expects the `_initialProver` to have already approved this address to spend at least the initial
/// liveness bond. This amount of tokens will be transferred from the `_initialProver` on the constructor at deployment.
abstract contract ERC20ProverManager is BaseProverManager {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;

    constructor(
        address _inbox,
        address _checkpointTracker,
        address _publicationFeed,
        address _initialProver,
        uint96 _initialFee,
        address _token,
        uint256 _initialDeposit
    ) BaseProverManager(_inbox, _checkpointTracker, _publicationFeed, _initialProver, _initialFee, _initialDeposit) {
        require(_token != address(0), "Token address cannot be 0");
        require(
            _initialDeposit >= _livenessBond(), "Initial deposit must be greater than or equal to the liveness bond"
        );

        token = IERC20(_token);

        // Deposit the amount of funds needed for the liveness bond from the `_initialProver`
        token.safeTransferFrom(_initialProver, address(this), _initialDeposit);
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
