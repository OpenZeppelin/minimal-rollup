// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IETHBridge} from "./IETHBridge.sol";

/// @dev Abstract ETH bridging contract to send native ETH between L1 <-> L2 using storage proofs.
///
/// IMPORTANT: No recovery mechanism is implemented in case an account creates a deposit that can't be claimed.
abstract contract ETHBridge is IETHBridge {
    mapping(bytes32 id => bool claimed) private _claimed;

    /// Incremental nonce to generate unique deposit IDs.
    uint256 private _globalDepositNonce;

    /// @inheritdoc IETHBridge
    function claimed(bytes32 id) public view virtual returns (bool) {
        return _claimed[id];
    }

    /// @inheritdoc IETHBridge
    function getDepositId(ETHDeposit memory ethDeposit) public view virtual returns (bytes32 id) {
        return _generateId(ethDeposit);
    }

    /// @inheritdoc IETHBridge
    // TODO: Possibly make this accept ETHDEeposit struct as input
    function deposit(address to, bytes memory data) public payable virtual returns (bytes32 id) {
        ETHDeposit memory ethDeposit = ETHDeposit(_globalDepositNonce, msg.sender, to, msg.value, data);
        id = _generateId(ethDeposit);
        unchecked {
            ++_globalDepositNonce;
        }
        emit DepositMade(id, ethDeposit);
    }

    /// @inheritdoc IETHBridge
    function claimDeposit(ETHDeposit memory deposit, uint256 height, bytes memory proof)
        external
        virtual
        returns (bytes32 id);

    /// @dev Processes deposit claim by id.
    /// @param id Identifier of the deposit
    /// @param ethDeposit Deposit to process
    function _processClaimDepositWithId(bytes32 id, ETHDeposit memory ethDeposit) internal virtual {
        require(!claimed(id), AlreadyClaimed());
        _claimed[id] = true;
        _sendETH(ethDeposit.to, ethDeposit.amount, ethDeposit.data);
        emit DepositClaimed(id, ethDeposit);
    }

    /// @dev Function to transfer ETH to the receiver but ignoring the returndata.
    /// @param to Address to send the ETH to
    /// @param value Amount of ETH to send
    /// @param data Data to send to the receiver
    function _sendETH(address to, uint256 value, bytes memory data) internal virtual {
        (bool success,) = to.call{value: value}(data);
        require(success, FailedClaim());
    }

    /// @dev Generates a unique ID for a deposit.
    /// @param ethDeposit Deposit to generate an ID for
    function _generateId(ETHDeposit memory ethDeposit) internal pure returns (bytes32) {
        return keccak256(abi.encode(ethDeposit));
    }
}
