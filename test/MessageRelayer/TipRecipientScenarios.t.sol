// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DefaultRecipientScenario} from "./DepositRecipientScenarios.t.sol";
import {GenericRecipient} from "./GenericRecipient.t.sol";

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

abstract contract TipRecipientScenarios is DefaultRecipientScenario {
    function test_TipRecipientScenarios_relayMessage_shouldTipCorrectRecipient() public ifRelaySucceeds {
        (GenericRecipient correctRecipient,) = _recipients();
        uint256 balanceBefore = address(correctRecipient).balance;
        _relayMessage();
        assertEq(address(correctRecipient).balance, balanceBefore + tip, "tip recipient balance mismatch");
    }

    function test_TipRecipientScenarios_relayMessage_shouldNotTipIncorrectRecipient() public ifRelaySucceeds {
        (, GenericRecipient incorrectRecipient) = _recipients();
        uint256 balanceBefore = address(incorrectRecipient).balance;
        _relayMessage();
        assertEq(address(incorrectRecipient).balance, balanceBefore, "incorrect tip recipient paid");
    }

    /// @param correctRecipient The user-selected recipient if it is set. The relayer-selected recipient otherwise.
    /// @param incorrectRecipient The other recipient, which should not receive the tip.
    /// @dev the only tested case where they are the same is when they are both zero (and the transaction reverts)
    function _recipients()
        internal
        view
        returns (GenericRecipient correctRecipient, GenericRecipient incorrectRecipient)
    {
        return userSelectedTipRecipient == GenericRecipient(payable(0))
            ? (relayerSelectedTipRecipient, userSelectedTipRecipient)
            : (userSelectedTipRecipient, relayerSelectedTipRecipient);
    }
}

// User-selected tip recipient scenarios

abstract contract UserSetValidTipRecipient is TipRecipientScenarios {
    function test_UserSetValidTipRecipient_claimDeposit_shouldTipUserSelectedRecipient() public ifClaimSucceeds {
        uint256 balanceBefore = address(userSelectedTipRecipient).balance;
        _claimDeposit();
        assertEq(address(userSelectedTipRecipient).balance, balanceBefore + tip, "tip recipient balance mismatch");
    }
}

abstract contract UserSetZeroTipRecipient is TipRecipientScenarios {
    function setUp() public virtual override {
        super.setUp();
        userSelectedTipRecipient = GenericRecipient(payable(0));
        _encodeReceiveCall();
        claimShouldSucceed = false;
    }
}

abstract contract UserSetInvalidTipRecipient is TipRecipientScenarios {
    function setUp() public virtual override {
        super.setUp();
        userSelectedTipRecipient.setSuccess(false);
        relayShouldSucceed = false;
        claimShouldSucceed = false;
    }
}

// Relayer-selected tip recipient scenarios

abstract contract RelayerSetValidTipRecipient is TipRecipientScenarios {}

abstract contract RelayerSetZeroTipRecipient is TipRecipientScenarios {
    function setUp() public virtual override {
        super.setUp();
        relayerSelectedTipRecipient = GenericRecipient(payable(0));
    }
}

abstract contract RelayerSetInvalidTipRecipient is TipRecipientScenarios {
    function setUp() public virtual override {
        super.setUp();
        relayerSelectedTipRecipient.setSuccess(false);
    }
}

// Combined scenarios

contract ValidUserTipRecipientOverrulesRelayer is UserSetValidTipRecipient, RelayerSetValidTipRecipient {}

contract InvalidUserTipRecipientOverrulesRelayer is UserSetInvalidTipRecipient, RelayerSetValidTipRecipient {
    function setUp() public override(InitialState, UserSetInvalidTipRecipient) {
        super.setUp();
    }
}

contract ValidRelayerTipRecipientUsed is UserSetZeroTipRecipient, RelayerSetValidTipRecipient {
    function setUp() public override(InitialState, UserSetZeroTipRecipient) {
        super.setUp();
    }
}

contract InvalidRelayerTipRecipientUsed is UserSetZeroTipRecipient, RelayerSetInvalidTipRecipient {
    function setUp() public override(UserSetZeroTipRecipient, RelayerSetInvalidTipRecipient) {
        super.setUp();
        relayShouldSucceed = false;
    }
}

contract NoTipRecipientSet is UserSetZeroTipRecipient, RelayerSetZeroTipRecipient {
    function setUp() public override(UserSetZeroTipRecipient, RelayerSetZeroTipRecipient) {
        super.setUp();
        relayShouldSucceed = false;
    }
}

// A valid scenario that can be used as a default scenario by unrelated tests.
abstract contract DefaultTipRecipientScenario is ValidUserTipRecipientOverrulesRelayer {}
