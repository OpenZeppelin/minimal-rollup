// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BridgedERC1155} from "./BridgedERC1155.sol";
import {IERC1155Bridge} from "./IERC1155Bridge.sol";
import {ISignalService} from "./ISignalService.sol";

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title ERC1155Bridge
/// @notice A decentralized bridge for ERC1155 tokens that allows anyone to initialize tokens
/// @dev Uses a permissionless token initialization flow
contract ERC1155Bridge is IERC1155Bridge, ReentrancyGuardTransient, IERC1155Receiver, ERC165 {
    /// @dev Signal type constants to differentiate signal categories
    bytes32 private constant TOKEN_DESCRIPTION_SIGNAL_PREFIX = keccak256("ERC1155_TOKEN_DESCRIPTION");
    bytes32 private constant DEPOSIT_SIGNAL_PREFIX = keccak256("ERC1155_DEPOSIT");

    mapping(bytes32 id => bool processed) private _processed;
    mapping(address originalToken => address counterpartToken) private _counterpartTokens;
    mapping(address token => bool isBridgedToken) private _isBridgedTokens;

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

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC1155Bridge).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IERC1155Bridge
    function processed(bytes32 id) public view returns (bool) {
        return _processed[id];
    }

    /// @inheritdoc IERC1155Bridge
    function getCounterpartToken(address originalToken) public view returns (address) {
        return _counterpartTokens[originalToken];
    }

    /// @inheritdoc IERC1155Bridge
    function getTokenDescriptionId(TokenDescription memory tokenDesc) public pure returns (bytes32 id) {
        return _generateTokenDescriptionId(tokenDesc);
    }

    /// @inheritdoc IERC1155Bridge
    function getDepositId(ERC1155Deposit memory erc1155Deposit) public pure returns (bytes32 id) {
        return _generateDepositId(erc1155Deposit);
    }

    /// @inheritdoc IERC1155Bridge
    function recordTokenDescription(address token) external returns (bytes32 id) {
        require(token != address(0), "Invalid token address");

        string memory uri;
        try IERC1155MetadataURI(token).uri(0) returns (string memory tokenUri) {
            uri = tokenUri;
        } catch {}

        TokenDescription memory tokenDesc = TokenDescription({originalToken: token, uri: uri});

        id = _generateTokenDescriptionId(tokenDesc);

        signalService.sendSignal(id);

        emit TokenDescriptionRecorded(id, tokenDesc);
    }

    /// @inheritdoc IERC1155Bridge
    function deployCounterpartToken(TokenDescription memory tokenDesc, uint256 height, bytes memory proof)
        external
        returns (address deployedToken)
    {
        bytes32 id = _generateTokenDescriptionId(tokenDesc);
        require(!_processed[id], CounterpartTokenAlreadyDeployed());
        require(
            _counterpartTokens[tokenDesc.originalToken] == address(0),
            "Counterpart token already exists for this original token"
        );

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        deployedToken = address(new BridgedERC1155(tokenDesc.uri, tokenDesc.originalToken));
        _counterpartTokens[tokenDesc.originalToken] = deployedToken;
        _isBridgedTokens[deployedToken] = true;
        _processed[id] = true;

        emit CounterpartTokenDeployed(id, tokenDesc, deployedToken);
    }

    /// @inheritdoc IERC1155Bridge
    function deposit(address to, address localToken, uint256 tokenId, uint256 amount, address canceler)
        external
        nonReentrant
        returns (bytes32 id)
    {
        bool isBridged = _isBridgedToken(localToken);
        address originalToken = isBridged ? BridgedERC1155(localToken).originalToken() : localToken;

        string memory tokenURI_;
        try IERC1155MetadataURI(localToken).uri(tokenId) returns (string memory uri) {
            tokenURI_ = uri;
        } catch {}

        ERC1155Deposit memory erc1155Deposit = ERC1155Deposit({
            nonce: _globalDepositNonce,
            from: msg.sender,
            to: to,
            originalToken: originalToken,
            tokenId: tokenId,
            amount: amount,
            tokenURI: tokenURI_,
            canceler: canceler
        });

        id = _generateDepositId(erc1155Deposit);
        unchecked {
            ++_globalDepositNonce;
        }

        IERC1155(localToken).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        if (isBridged) {
            BridgedERC1155(localToken).burn(tokenId, amount);
        }

        signalService.sendSignal(id);
        emit DepositMade(id, erc1155Deposit, localToken);
    }

    /// @inheritdoc IERC1155Bridge
    function claimDeposit(ERC1155Deposit memory erc1155Deposit, uint256 height, bytes memory proof)
        external
        nonReentrant
    {
        bytes32 id = _claimDeposit(erc1155Deposit, erc1155Deposit.to, height, proof);
        emit DepositClaimed(id, erc1155Deposit);
    }

    /// @inheritdoc IERC1155Bridge
    function cancelDeposit(ERC1155Deposit memory erc1155Deposit, address claimee, uint256 height, bytes memory proof)
        external
        nonReentrant
    {
        require(msg.sender == erc1155Deposit.canceler, OnlyCanceler());

        bytes32 id = _claimDeposit(erc1155Deposit, claimee, height, proof);

        emit DepositCancelled(id, claimee);
    }

    function _claimDeposit(ERC1155Deposit memory erc1155Deposit, address to, uint256 height, bytes memory proof)
        internal
        returns (bytes32 id)
    {
        id = _generateDepositId(erc1155Deposit);
        require(!processed(id), AlreadyClaimed());

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        _processed[id] = true;
        _sendERC1155(erc1155Deposit, to);
    }

    /// @dev Function to transfer ERC1155 to the receiver.
    /// @param erc1155Deposit The deposit information containing the original token address and tokenId
    /// @param to Address to send the tokens to
    function _sendERC1155(ERC1155Deposit memory erc1155Deposit, address to) internal {
        address deployedToken = _counterpartTokens[erc1155Deposit.originalToken];

        if (deployedToken != address(0)) {
            if (bytes(erc1155Deposit.tokenURI).length > 0) {
                BridgedERC1155(deployedToken).mintWithURI(
                    to, erc1155Deposit.tokenId, erc1155Deposit.amount, erc1155Deposit.tokenURI, ""
                );
            } else {
                BridgedERC1155(deployedToken).mint(to, erc1155Deposit.tokenId, erc1155Deposit.amount, "");
            }
        } else {
            IERC1155(erc1155Deposit.originalToken).safeTransferFrom(
                address(this), to, erc1155Deposit.tokenId, erc1155Deposit.amount, ""
            );
        }
    }

    /// @dev Checks if a token is a bridged token deployed by this bridge.
    /// @param token The token address to check
    /// @return true if the token is a bridged token deployed by this bridge
    function _isBridgedToken(address token) internal view returns (bool) {
        return _isBridgedTokens[token];
    }

    /// @dev Generates a unique ID for a token description.
    /// @param tokenDesc Token description to generate an ID for
    function _generateTokenDescriptionId(TokenDescription memory tokenDesc) internal pure returns (bytes32) {
        return keccak256(abi.encode(TOKEN_DESCRIPTION_SIGNAL_PREFIX, tokenDesc));
    }

    /// @dev Generates a unique ID for a deposit.
    /// @param erc1155Deposit Deposit to generate an ID for
    function _generateDepositId(ERC1155Deposit memory erc1155Deposit) internal pure returns (bytes32) {
        return keccak256(abi.encode(DEPOSIT_SIGNAL_PREFIX, erc1155Deposit));
    }
}
