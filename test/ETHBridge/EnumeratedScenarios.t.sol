// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DepositIsCancellable} from "./CancellableScenarios.t.sol";
import {BridgeHasNoEther, BridgeSufficientlyCapitalized} from "./CapitalizationScenarios.t.sol";
import {DepositIsClaimable, DepositIsNotClaimable} from "./ClaimableScenarios.t.sol";
import {DepositIsInvalidContractCall, DepositIsValidContractCall} from "./ContractCallValidityScenarios.t.sol";
import {CrossChainDepositExists} from "./CrossChainDepositExists.t.sol";
import {RecipientIsAContract, RecipientIsAnEOA} from "./RecipientScenarios.t.sol";
import {
    NonzeroETH_InvalidCallToPayableFn,
    NonzeroETH_NoCalldata,
    NonzeroETH_ValidCallToNonpayableFn,
    NonzeroETH_ValidCallToPayableFn,
    ZeroETH_InvalidCallToPayableFn,
    ZeroETH_NoCalldata,
    ZeroETH_ValidCallToNonpayableFn,
    ZeroETH_ValidCallToPayableFn
} from "./SampleDepositScenarios.t.sol";

// This is an empty deposit that does not transfer ETH or invoke a function call.
// Nobody should make this call but it is included for completeness.
contract EmptyCallToEOA is ZeroETH_NoCalldata, RecipientIsAnEOA, BridgeHasNoEther, DepositIsClaimable {}

// An empty deposit that does not transfer ETH. It passes no calldata to the recipient contract, which should fail
// (in our particular case, because the contract does not include a fallback function)
contract EmptyCallToContract is ZeroETH_NoCalldata, DepositIsInvalidContractCall {
    function setUp() public override(CrossChainDepositExists, DepositIsInvalidContractCall) {
        super.setUp();
    }
}

// An ETH transfer to an EOA with no calldata should succeed. This is a standard use case.
contract SimpleDepositToEOA is
    NonzeroETH_NoCalldata,
    RecipientIsAnEOA,
    BridgeSufficientlyCapitalized,
    DepositIsClaimable
{
    function setUp() public override(CrossChainDepositExists, BridgeSufficientlyCapitalized) {
        super.setUp();
    }
}

contract CancelDepositToEOA is
    NonzeroETH_NoCalldata,
    RecipientIsAnEOA,
    BridgeSufficientlyCapitalized,
    DepositIsCancellable
{
    function setUp() public override(CrossChainDepositExists, BridgeSufficientlyCapitalized) {
        super.setUp();
    }
}

// Same transfer as above, but the bridge does not have ETH. It should fail.
contract SimpleDepositToEOA_BridgeUndercollateralized is
    NonzeroETH_NoCalldata,
    RecipientIsAnEOA,
    BridgeHasNoEther,
    DepositIsNotClaimable
{}

// The bridge does a direct call (without the standard function invocation syntax). This means calldata passed to an EOA
// is ignored
// (and the call still succeeds)
contract InvokeFunctionOnEOA is
    NonzeroETH_ValidCallToPayableFn,
    RecipientIsAnEOA,
    BridgeSufficientlyCapitalized,
    DepositIsClaimable
{
    function setUp() public override(CrossChainDepositExists, BridgeSufficientlyCapitalized) {
        super.setUp();
    }
}

// We should be able to send ETH to a payable function on a contract. This is a standard use case.
contract DepositToPayableFunction is NonzeroETH_ValidCallToPayableFn, DepositIsValidContractCall {
    function setUp() public override(CrossChainDepositExists, DepositIsValidContractCall) {
        super.setUp();
    }
}

// We should not be able to send ETH to a nonpayable function on a contract.
contract DepositToNonPayableFunction is NonzeroETH_ValidCallToNonpayableFn, DepositIsInvalidContractCall {
    function setUp() public override(CrossChainDepositExists, DepositIsInvalidContractCall) {
        super.setUp();
    }
}

// We should be able to invoke a nonpayable function on a contract if we don't send ETH.
contract InvokeNonPayableFunction is ZeroETH_ValidCallToNonpayableFn, DepositIsValidContractCall {
    function setUp() public override(CrossChainDepositExists, DepositIsValidContractCall) {
        super.setUp();
    }
}

// If the contract call itself fails (inside the recipient contract), we should be unable to claim the deposit.
contract InvalidCallToPayableFunction is NonzeroETH_InvalidCallToPayableFn, DepositIsInvalidContractCall {
    function setUp() public override(CrossChainDepositExists, DepositIsInvalidContractCall) {
        super.setUp();
    }
}
