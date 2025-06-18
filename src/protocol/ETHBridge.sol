// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IETHBridge} from "./IETHBridge.sol";
import {ISignalService} from "./ISignalService.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

/// @dev In contrast to the `SignalService`, this contract does not expect the bridge to be deployed on the same
/// address on both chains. This is because it is designed so that each rollup has its own independent bridge contract,
/// and they may furthermore decide to deploy a new version of the bridge in the future.
contract ETHBridge is IETHBridge, ReentrancyGuardTransient {
    mapping(bytes32 id => bool) private _processed;

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
    function processed(bytes32 id) public view returns (bool) {
        return _processed[id];
    }

    /// @inheritdoc IETHBridge
    function getDepositId(ETHDeposit memory ethDeposit) public pure returns (bytes32 id) {
        return _generateId(ethDeposit);
    }

    /// @inheritdoc IETHBridge
    function deposit(address to, bytes memory data, bytes memory context, address canceler)
        public
        payable
        returns (bytes32 id)
    {
        ETHDeposit memory ethDeposit =
            ETHDeposit(_globalDepositNonce, msg.sender, to, msg.value, data, context, canceler);
        id = _generateId(ethDeposit);
        unchecked {
            ++_globalDepositNonce;
        }

        signalService.sendSignal(id);
        emit DepositMade(id, ethDeposit);
    }

    /// @inheritdoc IETHBridge
    function claimDeposit(ETHDeposit memory ethDeposit, uint256 height, bytes memory proof) external nonReentrant {
        bytes32 id = _claimDeposit(ethDeposit, ethDeposit.to, ethDeposit.data, height, proof);
        emit DepositClaimed(id, ethDeposit);
    }

    /// @inheritdoc IETHBridge
    function cancelDeposit(ETHDeposit memory ethDeposit, address claimee, uint256 height, bytes memory proof)
        external
    {
        require(msg.sender == ethDeposit.canceler, OnlyCanceler());

        bytes32 id = _claimDeposit(ethDeposit, claimee, bytes(""), height, proof);

        emit DepositCancelled(id, claimee);
    }

    function _claimDeposit(
        ETHDeposit memory ethDeposit,
        address to,
        bytes memory data,
        uint256 height,
        bytes memory proof
    ) internal returns (bytes32 id) {
        id = _generateId(ethDeposit);
        require(!processed(id), DepositAlreadyProcessed());

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        _processed[id] = true;
        _sendETH(to, ethDeposit.amount, data);
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
