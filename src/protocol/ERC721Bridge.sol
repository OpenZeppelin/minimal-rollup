// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC721Bridge} from "./IERC721Bridge.sol";
import {ISignalService} from "./ISignalService.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @dev In contrast to the `SignalService`, this contract does not expect the bridge to be deployed on the same
/// address on both chains. This is because it is designed so that each rollup has its own independent bridge contract,
/// and they may furthermore decide to deploy a new version of the bridge in the future.
contract ERC721Bridge is IERC721Bridge, ReentrancyGuardTransient, IERC721Receiver {
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

    /// @inheritdoc IERC721Receiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /// @inheritdoc IERC721Bridge
    function processed(bytes32 id) public view returns (bool) {
        return _processed[id];
    }

    /// @inheritdoc IERC721Bridge
    function getDepositId(ERC721Deposit memory erc721Deposit) public pure returns (bytes32 id) {
        return _generateId(erc721Deposit);
    }

    /// @inheritdoc IERC721Bridge
    function deposit(address to, address token, uint256 tokenId, bytes memory data, bytes memory context, address canceler)
        external returns (bytes32 id) {
        ERC721Deposit memory erc721Deposit =
            ERC721Deposit(_globalDepositNonce, msg.sender, to, token, tokenId, data, context, canceler);
        id = _generateId(erc721Deposit);
        unchecked {
            ++_globalDepositNonce;
        }

        IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);

        signalService.sendSignal(id);
        emit DepositMade(id, erc721Deposit);
    }

    /// @inheritdoc IERC721Bridge
    function claimDeposit(ERC721Deposit memory erc721Deposit, uint256 height, bytes memory proof) external nonReentrant {
        bytes32 id = _claimDeposit(erc721Deposit, erc721Deposit.to, erc721Deposit.data, height, proof);
        emit DepositClaimed(id, erc721Deposit);
    }

    /// @inheritdoc IERC721Bridge
    function cancelDeposit(ERC721Deposit memory erc721Deposit, address claimee, uint256 height, bytes memory proof)
        external nonReentrant {
        require(msg.sender == erc721Deposit.canceler, OnlyCanceler());

        bytes32 id = _claimDeposit(erc721Deposit, claimee, bytes(""), height, proof);

        emit DepositCancelled(id, claimee);
    }

    function _claimDeposit(
        ERC721Deposit memory erc721Deposit,
        address to,
        bytes memory data,
        uint256 height,
        bytes memory proof
    ) internal returns (bytes32 id) {
        id = _generateId(erc721Deposit);
        require(!processed(id), AlreadyClaimed());

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        _processed[id] = true;
        _sendERC721(erc721Deposit.token, to, erc721Deposit.tokenId, data);
    }

    /// @dev Function to safe transfer ERC721 to the receiver with data.
    /// @param token ERC721 token address
    /// @param to Address to send the token to
    /// @param tokenId Token ID to send
    /// @param data Data to send to the receiver
    function _sendERC721(address token, address to, uint256 tokenId, bytes memory data) internal {
        IERC721(token).safeTransferFrom(address(this), to, tokenId, data);
    }

    /// @dev Generates a unique ID for a deposit.
    /// @param erc721Deposit Deposit to generate an ID for
    function _generateId(ERC721Deposit memory erc721Deposit) internal pure returns (bytes32) {
        return keccak256(abi.encode(erc721Deposit));
    }
} 