// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BridgedERC721} from "./BridgedERC721.sol";
import {IERC721Bridge} from "./IERC721Bridge.sol";
import {ISignalService} from "./ISignalService.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

/// @title ERC721Bridge
/// @notice A decentralized bridge for ERC721 tokens that allows anyone to initialize tokens
/// @dev Uses a permissionless token initialization flow
contract ERC721Bridge is IERC721Bridge, ReentrancyGuardTransient, IERC721Receiver {
    /// @dev Signal type constants to differentiate signal categories
    bytes32 private constant TOKEN_DESCRIPTION_SIGNAL_PREFIX = keccak256("ERC721_TOKEN_DESCRIPTION");
    bytes32 private constant DEPOSIT_SIGNAL_PREFIX = keccak256("ERC721_DEPOSIT");

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

    /// @inheritdoc IERC721Receiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(IERC721Bridge).interfaceId;
    }

    /// @inheritdoc IERC721Bridge
    function processed(bytes32 id) public view returns (bool) {
        return _processed[id];
    }

    /// @inheritdoc IERC721Bridge
    function getDeployedToken(address originalToken) public view returns (address) {
        return _counterpartTokens[originalToken];
    }

    /// @inheritdoc IERC721Bridge
    function getTokenDescriptionId(TokenDescription memory tokenDesc) public pure returns (bytes32 id) {
        return _generateTokenDescriptionId(tokenDesc);
    }

    /// @inheritdoc IERC721Bridge
    function getDepositId(ERC721Deposit memory erc721Deposit) public pure returns (bytes32 id) {
        return _generateDepositId(erc721Deposit);
    }

    /// @inheritdoc IERC721Bridge
    function initializeToken(address token) external returns (bytes32 id) {
        require(token != address(0), "Invalid token address");

        string memory name;
        string memory symbol;

        try IERC721Metadata(token).name() returns (string memory _name) {
            name = _name;
        } catch {
            name = "Unknown NFT Name";
        }

        try IERC721Metadata(token).symbol() returns (string memory _symbol) {
            symbol = _symbol;
        } catch {
            symbol = "UNKNOWN";
        }

        TokenDescription memory tokenDesc = TokenDescription({originalToken: token, name: name, symbol: symbol});

        id = _generateTokenDescriptionId(tokenDesc);

        signalService.sendSignal(id);

        emit TokenDescriptionRecorded(id, tokenDesc);
    }

    /// @inheritdoc IERC721Bridge
    function deployCounterpartToken(TokenDescription memory tokenDesc, uint256 height, bytes memory proof)
        external
        returns (address deployedToken)
    {
        bytes32 id = _generateTokenDescriptionId(tokenDesc);
        require(!_processed[id], CounterpartTokenAlreadyDeployed());

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        _processed[id] = true;

        require(
            _counterpartTokens[tokenDesc.originalToken] == address(0),
            "Counterpart token already exists for this original token"
        );

        deployedToken = address(new BridgedERC721(tokenDesc.name, tokenDesc.symbol, tokenDesc.originalToken));

        _counterpartTokens[tokenDesc.originalToken] = deployedToken;

        _isBridgedTokens[deployedToken] = true;

        emit CounterpartTokenDeployed(id, tokenDesc, deployedToken);
    }

    /// @inheritdoc IERC721Bridge
    function deposit(address to, address originalToken, uint256 tokenId, address canceler)
        external
        nonReentrant
        returns (bytes32 id)
    {
        bool isBridged = _isBridgedToken(originalToken);

        string memory tokenURI;
        try IERC721Metadata(originalToken).tokenURI(tokenId) returns (string memory uri) {
            tokenURI = uri;
        } catch {}

        address actualOriginalToken;
        if (isBridged) {
            actualOriginalToken = BridgedERC721(originalToken).originalToken();
        } else {
            actualOriginalToken = originalToken;
        }

        ERC721Deposit memory erc721Deposit = ERC721Deposit({
            nonce: _globalDepositNonce,
            from: msg.sender,
            to: to,
            originalToken: actualOriginalToken,
            tokenId: tokenId,
            tokenURI: tokenURI,
            canceler: canceler
        });

        id = _generateDepositId(erc721Deposit);
        unchecked {
            ++_globalDepositNonce;
        }

        IERC721(originalToken).safeTransferFrom(msg.sender, address(this), tokenId);
        if (isBridged) {
            BridgedERC721(originalToken).burn(tokenId);
        }

        signalService.sendSignal(id);
        emit DepositMade(id, erc721Deposit, originalToken);
    }

    /// @inheritdoc IERC721Bridge
    function claimDeposit(ERC721Deposit memory erc721Deposit, uint256 height, bytes memory proof)
        external
        nonReentrant
    {
        bytes32 id = _claimDeposit(erc721Deposit, erc721Deposit.to, height, proof);
        emit DepositClaimed(id, erc721Deposit);
    }

    /// @inheritdoc IERC721Bridge
    function cancelDeposit(ERC721Deposit memory erc721Deposit, address claimee, uint256 height, bytes memory proof)
        external
        nonReentrant
    {
        require(msg.sender == erc721Deposit.canceler, OnlyCanceler());

        bytes32 id = _claimDeposit(erc721Deposit, claimee, height, proof);

        emit DepositCancelled(id, claimee);
    }

    function _claimDeposit(ERC721Deposit memory erc721Deposit, address to, uint256 height, bytes memory proof)
        internal
        returns (bytes32 id)
    {
        id = _generateDepositId(erc721Deposit);
        require(!processed(id), AlreadyClaimed());

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        _processed[id] = true;
        _sendERC721(erc721Deposit, to);
    }

    /// @dev Function to transfer ERC721 to the receiver.
    /// @param erc721Deposit The deposit information containing the original token address and tokenId
    /// @param to Address to send the token to
    function _sendERC721(ERC721Deposit memory erc721Deposit, address to) internal {
        address deployedToken = _counterpartTokens[erc721Deposit.originalToken];

        if (deployedToken != address(0)) {
            BridgedERC721(deployedToken).mint(to, erc721Deposit.tokenId, erc721Deposit.tokenURI);
        } else {
            IERC721(erc721Deposit.originalToken).safeTransferFrom(address(this), to, erc721Deposit.tokenId);
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
    /// @param erc721Deposit Deposit to generate an ID for
    function _generateDepositId(ERC721Deposit memory erc721Deposit) internal pure returns (bytes32) {
        return keccak256(abi.encode(DEPOSIT_SIGNAL_PREFIX, erc721Deposit));
    }
}
