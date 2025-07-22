// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC1155Bridge} from "./IERC1155Bridge.sol";
import {ISignalService} from "./ISignalService.sol";
import {BridgedERC1155} from "./BridgedERC1155.sol";

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

/// @title ERC1155Bridge
/// @notice A decentralized bridge for ERC1155 tokens that allows anyone to initialize tokens
/// @dev Uses a permissionless token initialization flow
contract ERC1155Bridge is IERC1155Bridge, ReentrancyGuardTransient, IERC1155Receiver {
    mapping(bytes32 id => bool processed) private _processed;
    mapping(bytes32 id => bool provenInitializations) private _provenInitializations;
    mapping(address token => bool initialized) private _initializedTokens;
    mapping(bytes32 key => address deployedToken) private _deployedTokens;

    /// Incremental nonce to generate unique deposit IDs.
    uint256 private _globalDepositNonce;
    
    /// Incremental nonce to generate unique initialization IDs.
    uint256 private _globalInitializationNonce;

    ISignalService public immutable signalService;

    /// @dev Trusted source of commitments in the `CommitmentStore` that the bridge will use to validate withdrawals
    /// @dev This is the Anchor on L2 and the Checkpoint Tracker on the L1
    address public immutable trustedCommitmentPublisher;

    /// @dev The counterpart bridge contract on the other chain.
    /// This is used to locate deposit signals inside the other chain's state root.
    /// WARN: This address has no significance (and may be untrustworthy) on this chain.
    address public immutable counterpart;
    
    /// @dev The chain identifier for this chain
    uint256 public immutable chainId;

    constructor(address _signalService, address _trustedCommitmentPublisher, address _counterpart) {
        require(_signalService != address(0), "Empty signal service");
        require(_trustedCommitmentPublisher != address(0), "Empty trusted publisher");
        require(_counterpart != address(0), "Empty counterpart");

        signalService = ISignalService(_signalService);
        trustedCommitmentPublisher = _trustedCommitmentPublisher;
        counterpart = _counterpart;
        chainId = block.chainid;
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

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }

    /// @inheritdoc IERC1155Bridge
    function processed(bytes32 id) public view returns (bool) {
        return _processed[id];
    }

    /// @inheritdoc IERC1155Bridge
    function isTokenInitialized(address token) public view returns (bool) {
        return _initializedTokens[token];
    }

    /// @inheritdoc IERC1155Bridge
    function isInitializationProven(bytes32 id) public view returns (bool) {
        return _provenInitializations[id];
    }

    /// @inheritdoc IERC1155Bridge
    function getDeployedToken(address originalToken, uint256 sourceChain) public view returns (address) {
        bytes32 key = keccak256(abi.encode(originalToken, sourceChain));
        return _deployedTokens[key];
    }

    /// @inheritdoc IERC1155Bridge
    function getInitializationId(TokenInitialization memory tokenInit) public pure returns (bytes32 id) {
        return _generateInitializationId(tokenInit);
    }

    /// @inheritdoc IERC1155Bridge
    function getDepositId(ERC1155Deposit memory erc1155Deposit) public pure returns (bytes32 id) {
        return _generateDepositId(erc1155Deposit);
    }

    /// @inheritdoc IERC1155Bridge
    function initializeToken(address token) external returns (bytes32 id) {
        require(token != address(0), "Invalid token address");
        require(!_initializedTokens[token], "Token already initialized");

        // Read token URI (base URI for the collection)
        string memory uri;
        try IERC1155MetadataURI(token).uri(0) returns (string memory tokenUri) {
            uri = tokenUri;
        } catch {
            // If uri call fails, use empty string
            uri = "";
        }

        TokenInitialization memory tokenInit = TokenInitialization({
            nonce: _globalInitializationNonce,
            originalToken: token,
            uri: uri,
            sourceChain: chainId
        });
        
        id = _generateInitializationId(tokenInit);
        unchecked {
            ++_globalInitializationNonce;
        }

        // Mark token as initialized locally
        _initializedTokens[token] = true;

        // Send signal for cross-chain initialization
        signalService.sendSignal(id);
        
        emit TokenInitialized(id, tokenInit);
    }

    /// @inheritdoc IERC1155Bridge
    function proveTokenInitialization(
        TokenInitialization memory tokenInit,
        uint256 height,
        bytes memory proof
    ) external returns (address deployedToken) {
        bytes32 id = _generateInitializationId(tokenInit);
        require(!_provenInitializations[id], InitializationAlreadyProven());

        // Verify the initialization signal from the source chain
        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        // Mark initialization as proven
        _provenInitializations[id] = true;

        // Deploy the bridged token
        deployedToken = address(new BridgedERC1155(
            tokenInit.uri,
            address(this),
            tokenInit.originalToken,
            tokenInit.sourceChain
        ));

        // Store the mapping
        bytes32 key = keccak256(abi.encode(tokenInit.originalToken, tokenInit.sourceChain));
        _deployedTokens[key] = deployedToken;

        emit TokenInitializationProven(id, tokenInit, deployedToken);
    }

    /// @inheritdoc IERC1155Bridge
    function deposit(
        address to,
        address localToken,
        uint256 tokenId,
        uint256 amount,
        address canceler
    ) external nonReentrant returns (bytes32 id) {
        // Check if token is initialized (for original tokens) or is a bridged token deployed by this bridge
        require(_initializedTokens[localToken] || _isBridgedToken(localToken), TokenNotInitialized());

        // Fetch the token URI for this specific token
        string memory tokenURI_;
        try IERC1155MetadataURI(localToken).uri(tokenId) returns (string memory uri) {
            tokenURI_ = uri;
        } catch {
            // If uri call fails, use empty string
            tokenURI_ = "";
        }

        ERC1155Deposit memory erc1155Deposit = ERC1155Deposit({
            nonce: _globalDepositNonce,
            from: msg.sender,
            to: to,
            localToken: localToken,
            sourceChain: chainId,
            tokenId: tokenId,
            amount: amount,
            tokenURI: tokenURI_,
            canceler: canceler
        });
        
        id = _generateDepositId(erc1155Deposit);
        unchecked {
            ++_globalDepositNonce;
        }

        // Handle token transfer based on whether it's a bridged token or original token
        if (_isBridgedToken(localToken)) {
            // This is a bridged token being sent back to its origin, burn it
            IERC1155(localToken).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
            BridgedERC1155(localToken).burn(address(this), tokenId, amount);
        } else {
            // This is an original token, hold it
            IERC1155(localToken).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        }

        // Send signal
        signalService.sendSignal(id);
        emit DepositMade(id, erc1155Deposit);
    }

    /// @inheritdoc IERC1155Bridge
    function claimDeposit(ERC1155Deposit memory erc1155Deposit, uint256 height, bytes memory proof) external nonReentrant {
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

    function _claimDeposit(
        ERC1155Deposit memory erc1155Deposit,
        address to,
        uint256 height,
        bytes memory proof
    ) internal returns (bytes32 id) {
        id = _generateDepositId(erc1155Deposit);
        require(!processed(id), AlreadyClaimed());

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        _processed[id] = true;
        _sendERC1155(erc1155Deposit, to);
    }

    /// @dev Function to transfer ERC1155 to the receiver.
    /// @param erc1155Deposit The deposit information containing the token and tokenId
    /// @param to Address to send the tokens to
    function _sendERC1155(ERC1155Deposit memory erc1155Deposit, address to) internal {
        if (erc1155Deposit.sourceChain != chainId) {
            // This is a deposit from another chain, check if we have the bridged token deployed
            bytes32 key = keccak256(abi.encode(erc1155Deposit.localToken, erc1155Deposit.sourceChain));
            address deployedToken = _deployedTokens[key];
            
            if (deployedToken != address(0)) {
                // Mint the bridged token with its original metadata
                if (bytes(erc1155Deposit.tokenURI).length > 0) {
                    BridgedERC1155(deployedToken).mintWithURI(to, erc1155Deposit.tokenId, erc1155Deposit.amount, erc1155Deposit.tokenURI, "");
                } else {
                    BridgedERC1155(deployedToken).mint(to, erc1155Deposit.tokenId, erc1155Deposit.amount, "");
                }
            } else {
                // This should not happen if token was properly initialized
                revert("Bridged token not found");
            }
        } else {
            // This is a deposit from the same chain (bridged token going back to origin)
            // Transfer the original token that we hold
            IERC1155(erc1155Deposit.localToken).safeTransferFrom(address(this), to, erc1155Deposit.tokenId, erc1155Deposit.amount, "");
        }
    }

    /// @dev Checks if a token is a bridged token deployed by this bridge.
    /// @param token The token address to check
    /// @return true if the token is a bridged token deployed by this bridge
    function _isBridgedToken(address token) internal view returns (bool) {
        try BridgedERC1155(token).bridge() returns (address bridge) {
            return bridge == address(this);
        } catch {
            return false;
        }
    }

    /// @dev Generates a unique ID for a token initialization.
    /// @param tokenInit Token initialization to generate an ID for
    function _generateInitializationId(TokenInitialization memory tokenInit) internal pure returns (bytes32) {
        return keccak256(abi.encode(tokenInit));
    }

    /// @dev Generates a unique ID for a deposit.
    /// @param erc1155Deposit Deposit to generate an ID for
    function _generateDepositId(ERC1155Deposit memory erc1155Deposit) internal pure returns (bytes32) {
        return keccak256(abi.encode(erc1155Deposit));
    }
}
