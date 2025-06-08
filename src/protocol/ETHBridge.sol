// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IETHBridge} from "./IETHBridge.sol";
import {ISignalService} from "./ISignalService.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

import {console} from "forge-std/console.sol";

/// @dev ETH bridging contract to send native ETH between L1 <-> L2 using storage proofs.
/// @dev In contracts to the `SignalService`, this contract does not expect the bridge to be deployed on the same
/// address on both chains. This is because it is designed so that each rollup has its own independent bridge contract,
/// and they may furthermore decide to deploy a new version of the bridge in the future.
///
/// IMPORTANT: No recovery mechanism is implemented in case an account creates a deposit that can't be claimed.
contract ETHBridge is IETHBridge, ReentrancyGuardTransient {
    mapping(bytes32 id => bool claimed) private _claimed;

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

    /// @inheritdoc IETHBridge
    function claimed(bytes32 id) public view returns (bool) {
        return _claimed[id];
    }

    /// @inheritdoc IETHBridge
    function getDepositId(ETHDeposit memory ethDeposit) public pure returns (bytes32 id) {
        return _generateId(ethDeposit);
    }

    /// @inheritdoc IETHBridge
    function deposit(address to, bytes memory data, address relayer) public payable returns (bytes32 id) {
        ETHDeposit memory ethDeposit = ETHDeposit(_globalDepositNonce, msg.sender, to, msg.value, data, relayer);
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
        require(!claimed(id), AlreadyClaimed());

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        _claimed[id] = true;
        _sendETH(ethDeposit.to, ethDeposit.amount, ethDeposit.data);

        emit DepositClaimed(id, ethDeposit);
    }

    /// @dev Function to transfer ETH to the receiver but ignoring the returndata.
    /// @param to Address to send the ETH to
    /// @param value Amount of ETH to send
    /// @param data Data to send to the receiver
    function _sendETH(address to, uint256 value, bytes memory data) internal {
        console.log(to);
        console.logBytes(data);
        (bool success,) = to.call{value: value}(data);
        require(success, FailedClaim());
    }

    /// @dev Generates a unique ID for a deposit.
    /// @param ethDeposit Deposit to generate an ID for
    function _generateId(ETHDeposit memory ethDeposit) internal pure returns (bytes32) {
        return keccak256(abi.encode(ethDeposit));
    }
}
