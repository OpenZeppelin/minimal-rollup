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
    bytes32 private constant INITIALIZATION_SIGNAL_PREFIX = keccak256("ERC721_TOKEN_INITIALIZATION");
    bytes32 private constant DEPOSIT_SIGNAL_PREFIX = keccak256("ERC721_DEPOSIT");

    mapping(bytes32 id => bool processed) private _processed;
    mapping(bytes32 id => bool provenInitializations) private _provenInitializations;
    mapping(address token => bool initialized) private _initializedTokens;
    mapping(bytes32 key => address deployedToken) private _deployedTokens;
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

    /// @inheritdoc IERC721Bridge
    function processed(bytes32 id) public view returns (bool) {
        return _processed[id];
    }

    /// @inheritdoc IERC721Bridge
    function isTokenInitialized(address token) public view returns (bool) {
        return _initializedTokens[token];
    }

    /// @inheritdoc IERC721Bridge
    function isInitializationProven(bytes32 id) public view returns (bool) {
        return _provenInitializations[id];
    }

    /// @inheritdoc IERC721Bridge
    function getDeployedToken(address originalToken) public view returns (address) {
        bytes32 key = keccak256(abi.encode(originalToken));
        return _deployedTokens[key];
    }

    /// @inheritdoc IERC721Bridge
    function getInitializationId(TokenInitialization memory tokenInit) public pure returns (bytes32 id) {
        return _generateInitializationId(tokenInit);
    }

    /// @inheritdoc IERC721Bridge
    function getDepositId(ERC721Deposit memory erc721Deposit) public pure returns (bytes32 id) {
        return _generateDepositId(erc721Deposit);
    }

    /// @inheritdoc IERC721Bridge
    function initializeToken(address token) external returns (bytes32 id) {
        require(token != address(0), "Invalid token address");
        require(!_initializedTokens[token], "Token already initialized");

        // Read token metadata with fallbacks for non-compliant tokens
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

        TokenInitialization memory tokenInit = TokenInitialization({originalToken: token, name: name, symbol: symbol});

        id = _generateInitializationId(tokenInit);

        // Mark token as initialized locally
        _initializedTokens[token] = true;

        // Send signal for cross-chain initialization
        signalService.sendSignal(id);

        emit TokenInitialized(id, tokenInit);
    }

    /// @inheritdoc IERC721Bridge
    function proveTokenInitialization(TokenInitialization memory tokenInit, uint256 height, bytes memory proof)
        external
        returns (address deployedToken)
    {
        bytes32 id = _generateInitializationId(tokenInit);
        require(!_provenInitializations[id], InitializationAlreadyProven());

        // Verify the initialization signal from the source chain
        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        // Mark initialization as proven
        _provenInitializations[id] = true;

        // Deploy the bridged token
        deployedToken = address(new BridgedERC721(tokenInit.name, tokenInit.symbol, tokenInit.originalToken));

        // Store the mapping
        bytes32 key = keccak256(abi.encode(tokenInit.originalToken));
        _deployedTokens[key] = deployedToken;

        // Mark as a bridged token deployed by this bridge
        _isBridgedTokens[deployedToken] = true;

        emit TokenInitializationProven(id, tokenInit, deployedToken);
    }

    /// @inheritdoc IERC721Bridge
    function deposit(address to, address localToken, uint256 tokenId, address canceler)
        external
        nonReentrant
        returns (bytes32 id)
    {
        // Check if token is initialized (for original tokens) or is a bridged token deployed by this bridge
        require(_initializedTokens[localToken] || _isBridgedToken(localToken), TokenNotInitialized());

        // Fetch the token URI for this specific token
        string memory tokenURI_;
        try IERC721Metadata(localToken).tokenURI(tokenId) returns (string memory uri) {
            tokenURI_ = uri;
        } catch {
            // If tokenURI call fails, use empty string
            tokenURI_ = "";
        }

        // Determine the original token address
        address originalToken;
        if (_isBridgedToken(localToken)) {
            // If depositing a bridged token, use its original token address
            originalToken = BridgedERC721(localToken).originalToken();
        } else {
            // If depositing an original token, use its address directly
            originalToken = localToken;
        }

        ERC721Deposit memory erc721Deposit = ERC721Deposit({
            nonce: _globalDepositNonce,
            from: msg.sender,
            to: to,
            localToken: originalToken,
            tokenId: tokenId,
            tokenURI: tokenURI_,
            canceler: canceler
        });

        id = _generateDepositId(erc721Deposit);
        unchecked {
            ++_globalDepositNonce;
        }

        // Handle token transfer based on whether it's a bridged token or original token
        if (_isBridgedToken(localToken)) {
            // This is a bridged token being sent back to its origin, burn it
            IERC721(localToken).safeTransferFrom(msg.sender, address(this), tokenId);
            BridgedERC721(localToken).burn(address(this), tokenId);
        } else {
            // This is an original token, hold it
            IERC721(localToken).safeTransferFrom(msg.sender, address(this), tokenId);
        }

        // Send signal
        signalService.sendSignal(id);
        emit DepositMade(id, erc721Deposit);
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
        // In a 1-1 bridge, use token mapping presence to determine mint vs transfer
        bytes32 key = keccak256(abi.encode(erc721Deposit.localToken));
        address deployedToken = _deployedTokens[key];

        if (deployedToken != address(0)) {
            // We have a bridged token for this original token → mint it with metadata
            if (bytes(erc721Deposit.tokenURI).length > 0) {
                BridgedERC721(deployedToken).mintWithURI(to, erc721Deposit.tokenId, erc721Deposit.tokenURI);
            } else {
                BridgedERC721(deployedToken).mint(to, erc721Deposit.tokenId);
            }
        } else {
            // No bridged token found → transfer the original token we're holding
            IERC721(erc721Deposit.localToken).safeTransferFrom(address(this), to, erc721Deposit.tokenId);
        }
    }

    /// @dev Checks if a token is a bridged token deployed by this bridge.
    /// @param token The token address to check
    /// @return true if the token is a bridged token deployed by this bridge
    function _isBridgedToken(address token) internal view returns (bool) {
        return _isBridgedTokens[token];
    }

    /// @dev Generates a unique ID for a token initialization.
    /// @param tokenInit Token initialization to generate an ID for
    function _generateInitializationId(TokenInitialization memory tokenInit) internal pure returns (bytes32) {
        return keccak256(abi.encode(INITIALIZATION_SIGNAL_PREFIX, tokenInit));
    }

    /// @dev Generates a unique ID for a deposit.
    /// @param erc721Deposit Deposit to generate an ID for
    function _generateDepositId(ERC721Deposit memory erc721Deposit) internal pure returns (bytes32) {
        return keccak256(abi.encode(DEPOSIT_SIGNAL_PREFIX, erc721Deposit));
    }
}
