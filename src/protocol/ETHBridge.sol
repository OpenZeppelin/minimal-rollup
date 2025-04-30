// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IETHBridge} from "./IETHBridge.sol";
import {ISignalService} from "./ISignalService.sol";

/// @dev ETH bridging contract to send native ETH between L1 <-> L2 using storage proofs.
///
/// IMPORTANT: No recovery mechanism is implemented in case an account creates a deposit that can't be claimed.
contract ETHBridge is IETHBridge {
    mapping(bytes32 id => bool claimed) private _claimed;

    /// Incremental nonce to generate unique deposit IDs.
    uint256 private _globalDepositNonce;

    ISignalService public immutable signalService;

    /// @dev This is the Anchor on L2 and the Checkpoint Tracker on the L1
    address public immutable trustedCommitmentPublisher;

    constructor(address _signalService, address _trustedCommitmentPublisher) {
        require(_signalService != address(0), "Empty signal service");
        require(_trustedCommitmentPublisher != address(0), "Empty trusted publisher");
        signalService = ISignalService(_signalService);
        trustedCommitmentPublisher = _trustedCommitmentPublisher;
    }

    /// @inheritdoc IETHBridge
    function claimed(bytes32 id) public view returns (bool) {
        return _claimed[id];
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
    // TODO: Non reentrant
    function claimDeposit(ETHDeposit memory ethDeposit, uint256 height, bytes memory proof) external {
        bytes32 id = _generateId(ethDeposit);
        signalService.verifySignal(height, trustedCommitmentPublisher, ethDeposit.from, id, proof);
        require(!claimed(id), AlreadyClaimed());
        _claimed[id] = true;
        _sendETH(ethDeposit.to, ethDeposit.amount, ethDeposit.data);
        emit DepositClaimed(id, ethDeposit);
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
