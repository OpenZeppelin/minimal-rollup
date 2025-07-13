// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20Bridge} from "./IERC20Bridge.sol";
import {ISignalService} from "./ISignalService.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

/// @dev In contrast to the `SignalService`, this contract does not expect the bridge to be deployed on the same
/// address on both chains. This is because it is designed so that each rollup has its own independent bridge contract,
/// and they may furthermore decide to deploy a new version of the bridge in the future.
contract ERC20Bridge is IERC20Bridge, ReentrancyGuardTransient {
    mapping(bytes32 id => bool processed) private _processed;

    /// Incremental nonce to generate unique deposit IDs.
    uint256 private _globalDepositNonce;

    ISignalService public immutable signalService;

    /// @dev Trusted source of commitments in the `CommitmentStore` that the bridge will use to validate withdrawals
    /// @dev This is the Anchor on L2 and the Checkpoint Tracker on the L1
    address public immutable trustedCommitmentPublisher;

    /// @dev The counterpart bridge contract on the other chain.
    /// This is used to locate deposit signals inside the other chain's state root.
    /// WARN: This address has no significance (and may be untrustworthy) on this chain.
    address public immutable counterpart;

    constructor(address _signalService, address _trustedCommitmentPublisher, address _counterpart) {
        require(_signalService != address(0), "Empty signal service");
        require(_trustedCommitmentPublisher != address(0), "Empty trusted publisher");
        require(_counterpart != address(0), "Empty counterpart");

        signalService = ISignalService(_signalService);
        trustedCommitmentPublisher = _trustedCommitmentPublisher;
        counterpart = _counterpart;
    }

    /// @inheritdoc IERC20Bridge
    function processed(bytes32 id) public view returns (bool) {
        return _processed[id];
    }

    /// @inheritdoc IERC20Bridge
    function getDepositId(ERC20Deposit memory erc20Deposit) public pure returns (bytes32 id) {
        return _generateId(erc20Deposit);
    }

    /// @inheritdoc IERC20Bridge
    function deposit(
        address to,
        address token,
        uint256 amount,
        bytes memory data,
        bytes memory context,
        address canceler
    ) external returns (bytes32 id) {
        ERC20Deposit memory erc20Deposit =
            ERC20Deposit(_globalDepositNonce, msg.sender, to, token, amount, data, context, canceler);
        id = _generateId(erc20Deposit);
        unchecked {
            ++_globalDepositNonce;
        }

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        signalService.sendSignal(id);
        emit DepositMade(id, erc20Deposit);
    }

    /// @inheritdoc IERC20Bridge
    function claimDeposit(ERC20Deposit memory erc20Deposit, uint256 height, bytes memory proof) external nonReentrant {
        bytes32 id = _claimDeposit(erc20Deposit, erc20Deposit.to, erc20Deposit.data, height, proof);
        emit DepositClaimed(id, erc20Deposit);
    }

    /// @inheritdoc IERC20Bridge
    function cancelDeposit(ERC20Deposit memory erc20Deposit, address claimee, uint256 height, bytes memory proof)
        external
        nonReentrant
    {
        require(msg.sender == erc20Deposit.canceler, OnlyCanceler());

        bytes32 id = _claimDeposit(erc20Deposit, claimee, bytes(""), height, proof);

        emit DepositCancelled(id, claimee);
    }

    function _claimDeposit(
        ERC20Deposit memory erc20Deposit,
        address to,
        bytes memory data,
        uint256 height,
        bytes memory proof
    ) internal returns (bytes32 id) {
        id = _generateId(erc20Deposit);
        require(!processed(id), AlreadyClaimed());

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        _processed[id] = true;
        _sendERC20(erc20Deposit.token, to, erc20Deposit.amount, data);
    }

    /// @dev Function to transfer ERC20 to the receiver and optionally call with data.
    /// @param token ERC20 token address
    /// @param to Address to send the tokens to
    /// @param amount Amount of tokens to send
    /// @param data Optional data to call the receiver with
    function _sendERC20(address token, address to, uint256 amount, bytes memory data) internal {
        IERC20(token).transfer(to, amount);
        if (data.length > 0) {
            (bool success,) = to.call(data);
            require(success, FailedClaim());
        }
    }

    /// @dev Generates a unique ID for a deposit.
    /// @param erc20Deposit Deposit to generate an ID for
    function _generateId(ERC20Deposit memory erc20Deposit) internal pure returns (bytes32) {
        return keccak256(abi.encode(erc20Deposit));
    }
}
