// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC1155Bridge} from "./IERC1155Bridge.sol";
import {ISignalService} from "./ISignalService.sol";

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @dev In contrast to the `SignalService`, this contract does not expect the bridge to be deployed on the same
/// address on both chains. This is because it is designed so that each rollup has its own independent bridge contract,
/// and they may furthermore decide to deploy a new version of the bridge in the future.
contract ERC1155Bridge is IERC1155Bridge, ReentrancyGuardTransient, IERC1155Receiver {
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

    /// @inheritdoc IERC1155Receiver
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /// @inheritdoc IERC1155Receiver
    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /// @inheritdoc IERC1155Bridge
    function processed(bytes32 id) public view returns (bool) {
        return _processed[id];
    }

    /// @inheritdoc IERC1155Bridge
    function getDepositId(ERC1155Deposit memory erc1155Deposit) public pure returns (bytes32 id) {
        return _generateId(erc1155Deposit);
    }

    /// @inheritdoc IERC1155Bridge
    function deposit(
        address to,
        address token,
        uint256 tokenId,
        uint256 amount,
        bytes memory data,
        bytes memory context,
        address canceler
    ) external returns (bytes32 id) {
        ERC1155Deposit memory erc1155Deposit =
            ERC1155Deposit(_globalDepositNonce, msg.sender, to, token, tokenId, amount, data, context, canceler);
        id = _generateId(erc1155Deposit);
        unchecked {
            ++_globalDepositNonce;
        }

        IERC1155(token).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        signalService.sendSignal(id);
        emit DepositMade(id, erc1155Deposit);
    }

    /// @inheritdoc IERC1155Bridge
    function claimDeposit(ERC1155Deposit memory erc1155Deposit, uint256 height, bytes memory proof)
        external
        nonReentrant
    {
        bytes32 id = _claimDeposit(erc1155Deposit, erc1155Deposit.to, erc1155Deposit.data, height, proof);
        emit DepositClaimed(id, erc1155Deposit);
    }

    /// @inheritdoc IERC1155Bridge
    function cancelDeposit(ERC1155Deposit memory erc1155Deposit, address claimee, uint256 height, bytes memory proof)
        external
        nonReentrant
    {
        require(msg.sender == erc1155Deposit.canceler, OnlyCanceler());

        bytes32 id = _claimDeposit(erc1155Deposit, claimee, bytes(""), height, proof);

        emit DepositCancelled(id, claimee);
    }

    function _claimDeposit(
        ERC1155Deposit memory erc1155Deposit,
        address to,
        bytes memory data,
        uint256 height,
        bytes memory proof
    ) internal returns (bytes32 id) {
        id = _generateId(erc1155Deposit);
        require(!processed(id), AlreadyClaimed());

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        _processed[id] = true;
        _sendERC1155(erc1155Deposit.token, to, erc1155Deposit.tokenId, erc1155Deposit.amount, data);
    }

    /// @dev Function to safe transfer ERC1155 to the receiver with data.
    /// @param token ERC1155 token address
    /// @param to Address to send the tokens to
    /// @param tokenId Token ID to send
    /// @param amount Amount of tokens to send
    /// @param data Data to send to the receiver
    function _sendERC1155(address token, address to, uint256 tokenId, uint256 amount, bytes memory data) internal {
        IERC1155(token).safeTransferFrom(address(this), to, tokenId, amount, data);
    }

    /// @dev Generates a unique ID for a deposit.
    /// @param erc1155Deposit Deposit to generate an ID for
    function _generateId(ERC1155Deposit memory erc1155Deposit) internal pure returns (bytes32) {
        return keccak256(abi.encode(erc1155Deposit));
    }
}
