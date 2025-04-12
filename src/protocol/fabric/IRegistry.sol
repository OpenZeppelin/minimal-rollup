// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import { IBLS } from "./IBLS.sol";
import { ISlasher } from "./ISlasher.sol";

interface IRegistry {
    /**
     *
     *                                *
     *            STRUCTS             *
     *                                *
     *
     */

    /// @notice A struct to track the configuration of the registry
    struct Config {
        /// The minimum collateral required to register
        uint80 minCollateralWei;
        /// The fraud proof window
        uint32 fraudProofWindow;
        /// The unregistration delay
        uint32 unregistrationDelay;
        /// The slash window
        uint32 slashWindow;
        /// The opt-in delay
        uint32 optInDelay;
    }

    /// @notice A registration of a BLS key
    struct SignedRegistration {
        /// BLS public key
        IBLS.G1Point pubkey;
        /// BLS signature
        IBLS.G2Point signature;
    }

    /// @notice Data about an operator
    /// @dev Since mappings cannot be returned from a contract, this struct is used to return operator data
    struct OperatorData {
        /// The authorized address of the operator
        address owner;
        /// ETH collateral in WEI
        uint80 collateralWei;
        /// The number of keys registered per operator
        uint16 numKeys;
        /// The block number when registration occurred
        uint48 registeredAt;
        /// The block number when deregistration occurred
        uint48 unregisteredAt;
        /// The block number when slashed from breaking a commitment
        uint48 slashedAt;
        /// A field to simulate deletion of the operator, since deleting a struct with a nested mapping is not safe
        bool deleted;
        /// Whether the operator has equivocated or not
        bool equivocated;
    }

    /// @notice An operator of BLS key[s]
    struct Operator {
        /// The data about the operator
        OperatorData data;
        /// Mapping to track opt-in and opt-out status for proposer commitment protocols
        mapping(address slasher => SlasherCommitment) slasherCommitments;
        /// Historical collateral records
        CollateralRecord[] collateralHistory;
    }

    /// @notice A struct to track opt-in and opt-out status for proposer commitment protocols
    struct SlasherCommitment {
        /// The address of the key used for commitments
        address committer;
        /// The block number when the operator opted in
        uint48 optedInAt;
        /// The block number when the operator opted out
        uint48 optedOutAt;
        /// Whether they have been slashed or not
        bool slashed;
    }

    /// @notice A record of collateral at a specific timestamp
    struct CollateralRecord {
        uint64 timestamp;
        uint80 collateralValue;
    }

    enum SlashingType {
        Fraud,
        Equivocation,
        Commitment
    }

    struct RegistrationProof {
        /// The merkle root of the registration merkle tree
        bytes32 registrationRoot;
        /// The registration to verify
        SignedRegistration registration;
        /// The merkle proof to verify the operator's key is in the registry
        bytes32[] merkleProof;
        /// The index of the leaf in the merkle tree
        uint256 leafIndex;
    }

    /**
     *
     *                                *
     *            FUNCTIONS           *
     *                                *
     *
     */

    /// @notice Batch registers an operator's BLS keys and collateral to the URC
    /// @dev SignedRegistration signatures are optimistically verified. They are expected to be signed with the `DOMAIN_SEPARATOR` mixin.
    /// @dev The function will merkleize the supplied `registrations` and map the registration merkle root to an Operator struct.
    /// @dev The function will revert if:
    /// @dev - They sent less than `config.minCollateralWei` (InsufficientCollateral)
    /// @dev - The operator has already registered the same `registrations` (OperatorAlreadyRegistered)
    /// @dev - The registration root is invalid (InvalidRegistrationRoot)
    /// @param registrations The BLS keys to register
    /// @param owner The authorized address to perform actions on behalf of the operator
    /// @return registrationRoot The merkle root of the registration
    function register(SignedRegistration[] calldata registrations, address owner)
        external
        payable
        returns (bytes32 registrationRoot);

    /// @notice Starts the process to unregister an operator from the URC
    /// @dev The function will mark the `unregisteredAt` timestamp in the Operator struct. The operator can claim their collateral after the `unregistrationDelay` more blocks have passed.
    /// @dev The function will revert if:
    /// @dev - The operator has already been deleted (OperatorDeleted)
    /// @dev - The caller is not the operator's owner (WrongOperator)
    /// @dev - The operator has already unregistered (AlreadyUnregistered)
    /// @dev - The operator has been slashed (SlashingAlreadyOccurred)
    /// @param registrationRoot The merkle root generated and stored from the register() function
    function unregister(bytes32 registrationRoot) external;

    /// @notice Opts an operator into a proposer commtiment protocol via Slasher contract
    /// @dev The function will revert if:
    /// @dev - The operator has already been deleted (OperatorDeleted)
    /// @dev - The caller is not the operator's owner (WrongOperator)
    /// @dev - The fraud proof window has not passed (FraudProofWindowNotMet)
    /// @dev - The operator has already been slashed (SlashingAlreadyOccurred)
    /// @dev - The operator has already opted in (AlreadyOptedIn)
    /// @dev - The opt-in delay has not passed (OptInDelayNotMet)
    /// @param registrationRoot The merkle root generated and stored from the register() function
    /// @param slasher The address of the Slasher contract to opt into
    /// @param committer The address of the key to be used for making commitments
    function optInToSlasher(bytes32 registrationRoot, address slasher, address committer) external;

    /// @notice Opts an operator out of a slasher
    /// @dev The function will revert if:
    /// @dev - The operator has already been deleted (OperatorDeleted)
    /// @dev - The caller is not the operator's owner (WrongOperator)
    /// @dev - The operator has is not currently opted in (NotOptedIn)
    /// @dev - The opt-in delay has not passed (OptInDelayNotMet)
    /// @param registrationRoot The merkle root generated and stored from the register() function
    /// @param slasher The address of the Slasher contract to opt out of
    function optOutOfSlasher(bytes32 registrationRoot, address slasher) external;

    /// @notice Slash an operator for previously submitting a fraudulent `SignedRegistration` in the register() function
    /// @dev To save BLS verification gas costs, the URC optimistically accepts registration signatures. This function allows a challenger to slash the operator by executing the BLS verification logic to prove the registration was fraudulent.
    /// @dev A successful challenge will transfer `config.minCollateralWei / 2` to the challenger, burn `config.minCollateralWei / 2`, and then allow the operator to claim their remaining collateral after `config.slashWindow` blocks have elapsed from the `claimSlashedCollateral()` function.
    /// @dev The function will revert if:
    /// @dev - The operator has already been deleted (OperatorDeleted)
    /// @dev - The fraud proof window has expired (FraudProofWindowExpired)
    /// @dev - The operator has no collateral (NoCollateral)
    /// @dev - The operator's collateral is less than the minimum collateral (CollateralBelowMinimum)
    /// @dev - The registration merkle proof is invalid (InvalidProof)
    /// @dev - The BLS signature was actually valid (FraudProofChallengeInvalid)
    /// @dev - ETH transfer to challenger fails (EthTransferFailed)
    /// @param proof The merkle proof to verify the operator's key is in the registry
    /// @return slashedCollateralWei The amount of WEI slashed
    function slashRegistration(RegistrationProof calldata proof) external returns (uint256 slashedCollateralWei);

    /// @notice Slashes an operator for breaking a commitment
    /// @dev The function verifies `proof` to first ensure the operator's BLS key is in the registry, then verifies the `signedDelegation` was signed by the same key. If the fraud proof window has passed, the URC will call the `slash()` function of the Slasher contract specified in the `signedCommitment`. The Slasher contract will determine if the operator has broken a commitment and return the amount of WEI to be slashed at the URC.
    /// @dev The function will burn `slashAmountWei`. It will also save the timestamp of the slashing to start the `config.slashWindow` in case of multiple slashings.
    /// @dev The function will revert if:
    /// @dev - The operator has already been deleted (OperatorDeleted)
    /// @dev - The same slashing inputs have been supplied before (SlashingAlreadyOccurred)
    /// @dev - The fraud proof window has not passed (FraudProofWindowNotMet)
    /// @dev - The operator has already unregistered (OperatorAlreadyUnregistered)
    /// @dev - The slash window has expired (SlashWindowExpired)
    /// @dev - The merkle proof is invalid (InvalidProof)
    /// @dev - The signed delegation was not signed by the operator's BLS key (DelegationSignatureInvalid)
    /// @dev - The commitment was not signed by the delegated committer address (UnauthorizedCommitment)
    /// @dev - The slash amount exceeds the operator's collateral (SlashAmountExceedsCollateral)
    /// @param proof The merkle proof to verify the operator's key is in the registry
    /// @param delegation The SignedDelegation signed by the operator's BLS key
    /// @param commitment The SignedCommitment signed by the delegate's ECDSA key
    /// @param evidence Arbitrary evidence to slash the operator, required by the Slasher contract
    /// @return slashAmountWei The amount of WEI slashed
    function slashCommitment(
        RegistrationProof calldata proof,
        ISlasher.SignedDelegation calldata delegation,
        ISlasher.SignedCommitment calldata commitment,
        bytes calldata evidence
    ) external returns (uint256 slashAmountWei);

    /// @notice Slashes an operator for breaking a commitment in a protocol they opted into via the optInToSlasher() function. The operator must have already opted into the protocol.
    /// @dev The function verifies the commitment was signed by the registered committer from the optInToSlasher() function before calling into the Slasher contract.
    /// @dev Reverts if:
    /// @dev - The operator has already been deleted (OperatorDeleted)
    /// @dev - The fraud proof window has not passed (FraudProofWindowNotMet)
    /// @dev - The operator has already unregistered and delay passed (OperatorAlreadyUnregistered)
    /// @dev - The slash window has expired (SlashWindowExpired)
    /// @dev - The operator has not opted into the slasher (NotOptedIn)
    /// @dev - The commitment was not signed by registered committer (UnauthorizedCommitment)
    /// @dev - The slash amount exceeds operator's collateral (SlashAmountExceedsCollateral)
    /// @param registrationRoot The merkle root generated and stored from the register() function
    /// @param commitment The SignedCommitment signed by the delegate's ECDSA key
    /// @param evidence Arbitrary evidence to slash the operator, required by the Slasher contract
    /// @return slashAmountWei The amount of WEI slashed
    function slashCommitment(
        bytes32 registrationRoot,
        ISlasher.SignedCommitment calldata commitment,
        bytes calldata evidence
    ) external returns (uint256 slashAmountWei);

    /// @notice Slash an operator for equivocation (signing two different delegations for the same slot)
    /// @dev A successful challenge will transfer `config.minCollateralWei / 2` to the challenger, burn `config.minCollateralWei / 2`, and then allow the operator to claim their remaining collateral after `config.slashWindow` blocks have elapsed from the `claimSlashedCollateral()` function.
    /// @dev Reverts if:
    /// @dev - The operator has already been deleted (OperatorDeleted)
    /// @dev - The operator has already equivocated (OperatorAlreadyEquivocated)
    /// @dev - The delegations are the same (DelegationsAreSame)
    /// @dev - The fraud proof window has not passed (FraudProofWindowNotMet)
    /// @dev - The operator has already unregistered and delay passed (OperatorAlreadyUnregistered)
    /// @dev - The slash window has expired (SlashWindowExpired)
    /// @dev - The merkle proof is invalid (InvalidProof)
    /// @dev - Either delegation is invalid (InvalidDelegation)
    /// @dev - The delegations are for different slots (DifferentSlots)
    /// @dev - ETH transfer to challenger fails (EthTransferFailed)
    /// @param proof The merkle proof to verify the operator's key is in the registry
    /// @param delegationOne The first SignedDelegation signed by the operator's BLS key
    /// @param delegationTwo The second SignedDelegation signed by the operator's BLS key
    /// @return slashAmountWei The amount of WEI slashed
    function slashEquivocation(
        RegistrationProof calldata proof,
        ISlasher.SignedDelegation calldata delegationOne,
        ISlasher.SignedDelegation calldata delegationTwo
    ) external returns (uint256 slashAmountWei);

    /// @notice Adds collateral to an Operator struct
    /// @dev The function will revert if:
    /// @dev - The operator was deleted (OperatorDeleted)
    /// @dev - The operator is at 0 wei collateral (NoCollateral)
    /// @dev - The input collateral amount overflows the `collateralWei` field (CollateralOverflow)
    /// @param registrationRoot The merkle root generated and stored from the register() function
    function addCollateral(bytes32 registrationRoot) external payable;

    /// @notice Retrieves an operator's collateral after the unregistration delay has elapsed
    /// @dev The function will revert if:
    /// @dev - The operator has already been deleted (OperatorDeleted)
    /// @dev - The operator has not previously unregistered via `unregister()` (NotUnregistered)
    /// @dev - The `unregistrationDelay` has not passed (UnregistrationDelayNotMet)
    /// @dev - The operator was slashed (they will need to call `claimSlashedCollateral()`) (SlashingAlreadyOccurred)
    /// @dev - ETH transfer to operator fails (EthTransferFailed)
    /// @dev The function will transfer the operator's collateral to their registered `owner` address.
    /// @param registrationRoot The merkle root generated and stored from the register() function
    function claimCollateral(bytes32 registrationRoot) external;

    /// @notice Retrieves an operator's collateral if they have been slashed before
    /// @dev The function will revert if:
    /// @dev - The operator has already been deleted (OperatorDeleted)
    /// @dev - The operator has not been slashed (NotSlashed)
    /// @dev - The slash window has not passed (SlashWindowNotMet)
    /// @dev - ETH transfer to operator fails (EthTransferFailed)
    function claimSlashedCollateral(bytes32 registrationRoot) external;

    // =========== getter functions ===========

    /// @notice Get the configuration of the registry
    /// @return config The configuration of the registry
    function getConfig() external view returns (Config memory config);

    /// @notice Returns information about an operator
    /// @param registrationRoot The merkle root generated and stored from the register() function
    /// @return operatorData The data about the operator
    function getOperatorData(bytes32 registrationRoot) external view returns (OperatorData memory operatorData);

    /// @notice Verify a merkle proof against a given `RegistrationProof`
    /// @dev The function will revert if the proof is invalid
    /// @dev The function checks against registered operators to get the owner address and
    /// @dev should revert if the proof doesn't correspond to a real registration
    /// @param proof The merkle proof to verify the operator's key is in the registry
    function verifyMerkleProof(RegistrationProof calldata proof) external view;

    /// @notice Checks if an operator is opted into a protocol
    /// @param registrationRoot The merkle root generated and stored from the register() function
    /// @param slasher The address of the slasher to check
    /// @return slasherCommitment The slasher commitment (default values if not opted in)
    function getSlasherCommitment(bytes32 registrationRoot, address slasher)
        external
        view
        returns (SlasherCommitment memory);

    /// @notice Returns true if the operator has been slashed
    /// @param registrationRoot The merkle root generated and stored from the register() function
    /// @return slashed True if the operator has been slashed, false otherwise
    function isSlashed(bytes32 registrationRoot) external view returns (bool slashed);

    /// @notice Returns true if the operator has been slashed for a given slasher
    /// @param registrationRoot The merkle root generated and stored from the register() function
    /// @param slasher The address of the slasher to check
    /// @return slashed True if the operator has been slashed, false otherwise
    function isSlashed(bytes32 registrationRoot, address slasher) external view returns (bool slashed);

    /// @notice Checks if an operator is opted into a protocol and hasn't been slashed
    /// @param registrationRoot The merkle root generated and stored from the register() function
    /// @param slasher The address of the slasher to check
    /// @return True if the operator is opted in and hasn't been slashed, false otherwise
    function isOptedIntoSlasher(bytes32 registrationRoot, address slasher) external view returns (bool);

    /// @notice Returns the operator data for a given `RegistrationProof` iff the proof is valid
    /// @dev The function will revert if the proof is invalid
    /// @param proof The merkle proof to verify the operator's key is in the registry
    /// @return operatorData The operator data
    function getVerifiedOperatorData(RegistrationProof calldata proof) external view returns (OperatorData memory);

    /// @notice Checks if a slashing has already occurred with the same input
    /// @dev The getter for the `slashedBefore` mapping
    /// @param slashingDigest The digest of the slashing evidence
    /// @return True if the slashing has already occurred, false otherwise
    function slashingEvidenceAlreadyUsed(bytes32 slashingDigest) external view returns (bool);

    /// @notice Retrieves the historical collateral value for an operator at a given timestamp
    /// @param registrationRoot The merkle root generated and stored from the register() function
    /// @param timestamp The timestamp to retrieve the collateral value for
    /// @return collateralWei The collateral amount in WEI at the closest recorded timestamp
    function getHistoricalCollateral(bytes32 registrationRoot, uint256 timestamp)
        external
        view
        returns (uint256 collateralWei);

    /// @notice Returns a `RegistrationProof` for a given `SignedRegistration` array
    /// @dev This function is not intended to be called on-chain due to gas costs
    /// @param regs The array of all `SignedRegistration` structs submitted during the initial call to `register()`
    /// @param owner The owner address of the operator
    /// @param leafIndex The index of the leaf the proof is for
    /// @return proof The `RegistrationProof` for the given `SignedRegistration` array
    function getRegistrationProof(SignedRegistration[] calldata regs, address owner, uint256 leafIndex)
        external
        pure
        returns (RegistrationProof memory proof);
}
