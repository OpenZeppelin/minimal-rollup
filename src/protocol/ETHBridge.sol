// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IETHBridge} from "./IETHBridge.sol";
import {ISignalService} from "./ISignalService.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

/// @dev ETH bridging contract to send native ETH between L1 <-> L2 using storage proofs.
///
/// IMPORTANT: No recovery mechanism is implemented in case an account creates a deposit that can't be claimed.
contract ETHBridge is IETHBridge, ReentrancyGuardTransient {
    mapping(bytes32 id => Status status) private _depositStatus;

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

        signalService = ISignalService(_signalService);
        trustedCommitmentPublisher = _trustedCommitmentPublisher;
        counterpart = _counterpart;
    }

    /// @inheritdoc IETHBridge
    /// @dev The `NONE` status does not indicate that the deposit does not exist
    /// but rather that the deposit has not been processed yet (it may also not exist),
    /// use isSignalStored to verify the existence of a deposit.
    function getDepositStatus(bytes32 id) public view returns (Status) {
        return _depositStatus[id];
    }

    /// @inheritdoc IETHBridge
    function getDepositId(ETHDeposit memory ethDeposit) public pure returns (bytes32 id) {
        return _generateId(ethDeposit);
    }

    /// @inheritdoc IETHBridge
    function deposit(address to, bytes memory data) public payable returns (bytes32 id) {
        ETHDeposit memory ethDeposit = ETHDeposit(_globalDepositNonce, msg.sender, to, msg.value, data);
        id = _generateId(ethDeposit);
        unchecked {
            ++_globalDepositNonce;
        }

        signalService.sendSignal(id);
        emit DepositMade(id, ethDeposit);
    }

    /// @inheritdoc IETHBridge
    function claimDeposit(ETHDeposit memory ethDeposit, uint256 height, bytes memory proof) external nonReentrant {
        bytes32 id = _generateId(ethDeposit);
        require(getDepositStatus(id) == Status.NONE, AlreadyClaimed());

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        _depositStatus[id] = Status.PROCESSED;
        _sendETH(ethDeposit.to, ethDeposit.amount, ethDeposit.data);

        emit DepositClaimed(id, ethDeposit);
    }

    /// @inheritdoc IETHBridge
    function cancelDeposit(ETHDeposit memory ethDeposit) external {
        bytes32 id = _generateId(ethDeposit);
        require(msg.sender == ethDeposit.from, OnlyDepositer());
        require(getDepositStatus(id) == Status.NONE, DepositAlreadyProcessed());

        _depositStatus[id] = Status.CANCELLED;

        bytes32 cancelledDepositId = id ^ bytes32(uint256(Status.CANCELLED));
        signalService.sendSignal(cancelledDepositId);

        emit DepositCancelled(id, cancelledDepositId);
    }

    /// @inheritdoc IETHBridge
    function claimCancelledDeposit(ETHDeposit memory ethDeposit, uint256 height, bytes memory proof)
        external
        nonReentrant
    {
        bytes32 id = _generateId(ethDeposit);
        require(getDepositStatus(id) == Status.NONE, DepositAlreadyProcessed());
        bytes32 cancelledDepositId = id ^ bytes32(uint256(Status.CANCELLED));

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, cancelledDepositId, proof);

        _depositStatus[id] = Status.PROCESSED;
        //CHECK: send to depositor or from.. should be the same address by i feel from is safer
        _sendETH(ethDeposit.from, ethDeposit.amount, "");
    }

    /// @dev Function to transfer ETH to the receiver but ignoring the returndata.
    /// @param to Address to send the ETH to
    /// @param value Amount of ETH to send
    /// @param data Data to send to the receiver
    function _sendETH(address to, uint256 value, bytes memory data) internal {
        (bool success,) = to.call{value: value}(data);
        require(success, FailedClaim());
    }

    /// @dev Generates a unique ID for a deposit.
    /// @param ethDeposit Deposit to generate an ID for
    function _generateId(ETHDeposit memory ethDeposit) internal pure returns (bytes32) {
        return keccak256(abi.encode(ethDeposit));
    }
}
