// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {MockERC20} from "../mocks/MockERC20.sol";
import {InitialState} from "./InitialState.t.sol";
import {BaseProverManager} from "src/protocol/BaseProverManager.sol";
import {ERC20ProverManager} from "src/protocol/ERC20ProverManager.sol";
import {ETHProverManager} from "src/protocol/ETHProverManager.sol";

abstract contract ETHCurrency is InitialState {
    function _createProverManager() internal virtual override returns (BaseProverManager) {
        vm.deal(deployer, initialDeposit);
        vm.prank(deployer);
        return new ETHProverManager{value: initialDeposit}(
            address(inbox), address(checkpointTracker), initialProver, initialFee
        );
    }

    function _prefund(address account, uint256 amount) internal override {
        vm.deal(account, amount);
    }

    function _prepareForDeposit(address depositor, uint256 amount) internal virtual override {
        // Do nothing
    }

    function _executeDeposit(address depositor, uint256 amount) internal override {
        vm.prank(depositor);
        ETHProverManager(payable(address(proverManager))).deposit{value: amount}();
    }

    function _currencyBalance(address account) internal view override returns (uint256) {
        return account.balance;
    }
}

abstract contract ERC20Currency is InitialState {
    MockERC20 public token;

    function setUp() public virtual override {
        token = new MockERC20("MockERC20", "MCK");
        // do not call super.setUp() because it will be called by the Test contract
    }

    function _createProverManager() internal virtual override returns (BaseProverManager) {
        bytes32 salt = bytes32(uint256(1));
        address pmAddress = vm.computeCreate2Address(
            salt,
            keccak256(
                abi.encodePacked(
                    type(ERC20ProverManager).creationCode,
                    abi.encode(
                        address(inbox),
                        address(checkpointTracker),
                        initialProver,
                        initialFee,
                        address(token),
                        initialDeposit
                    )
                )
            )
        );

        token.mint(initialProver, initialDeposit);
        vm.prank(initialProver);
        token.approve(pmAddress, initialDeposit);

        vm.prank(deployer);
        return new ERC20ProverManager{salt: salt}(
            address(inbox), address(checkpointTracker), initialProver, initialFee, address(token), initialDeposit
        );
    }

    function _prefund(address account, uint256 amount) internal override {
        // to match the vm.deal behavior, this should replace the account's balance with the new amount
        uint256 currentBalance = token.balanceOf(account);
        // Cannot prefund if current balance is greater than prefund amount
        assert(currentBalance <= amount);
        token.mint(account, amount - currentBalance);
    }

    function _prepareForDeposit(address depositor, uint256 amount) internal virtual override {
        vm.prank(depositor);
        token.approve(address(proverManager), amount);
    }

    function _executeDeposit(address depositor, uint256 amount) internal override {
        vm.prank(depositor);
        ERC20ProverManager(address(proverManager)).deposit(amount);
    }

    function _currencyBalance(address account) internal view override returns (uint256) {
        return token.balanceOf(account);
    }
}
