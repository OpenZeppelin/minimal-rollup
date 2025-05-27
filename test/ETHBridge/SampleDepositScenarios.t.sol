// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CrossChainDepositExists} from "./CrossChainDepositExists.t.sol";

// The scenarios provided in SampleDepositProof.t.sol

abstract contract ZeroETH_NoCalldata is CrossChainDepositExists {
    function _depositIdx() internal pure override returns (uint256) {
        return 0;
    }
}

abstract contract ZeroETH_ValidCallToPayableFn is CrossChainDepositExists {
    function _depositIdx() internal pure override returns (uint256) {
        return 1;
    }
}

abstract contract ZeroETH_InvalidCallToPayableFn is CrossChainDepositExists {
    function _depositIdx() internal pure override returns (uint256) {
        return 2;
    }
}

abstract contract ZeroETH_ValidCallToNonpayableFn is CrossChainDepositExists {
    function _depositIdx() internal pure override returns (uint256) {
        return 3;
    }
}

abstract contract NonzeroETH_NoCalldata is CrossChainDepositExists {
    function _depositIdx() internal pure override returns (uint256) {
        return 4;
    }
}

abstract contract NonzeroETH_ValidCallToPayableFn is CrossChainDepositExists {
    function _depositIdx() internal pure override returns (uint256) {
        return 5;
    }
}

abstract contract NonzeroETH_InvalidCallToPayableFn is CrossChainDepositExists {
    function _depositIdx() internal pure override returns (uint256) {
        return 6;
    }
}

abstract contract NonzeroETH_ValidCallToNonpayableFn is CrossChainDepositExists {
    function _depositIdx() internal pure override returns (uint256) {
        return 7;
    }
}
