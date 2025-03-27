# Style Guide

A minimal set of conventions help keep our contracts consistent, and ensure our PR discussions are focused on the code changes, and not the style.
This guide is not intended to be comprehensive, but rather to provide a starting point for the style of the code.

## Style

### Unless an exception or addition is specifically noted, we follow the [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)

1. Private state variables should be prefixed with an underscore.

    ```solidity
    uint256 private _totalSupply;
    ```

1. Private or internal functions should be prefixed with an underscore.

    ```solidity
    function _transfer(address from, address to, uint256 amount) internal {
        // ...
    }
    ```

1. Event names should be in the past tense.

    Events should track things that happened and so should be past tense. Using past tense also helps avoid naming collisions with structs or functions.

    ```solidity
    event Published();
    ```

1. Constructor parameters, when they overshade a state variable, should be prefixed with an underscore.

    ```solidity
    constructor(uint256 _totalSupply) {
        totalSupply = _totalSupply;
    }
    ```

1. Local variables or function parameters when they overshade a state variable should be suffixed with an underscore.

    ```solidity
    uint256 public totalSupply;
    address public owner;

    function setTotalSupply(uint256 totalSupply_) public {
        totalSupply = totalSupply_;
        address owner_ = msg.sender;
        owner = owner_;
    }
    ```

1. Events and structs when part of the contract's public API should be defined in the contract interface.

    If they are an implementation detail, or emitted by a specific implementation, they should instead be defined in the contract itself, and not part of the interface.
    ```solidity
    interface IMyContract {
        // These event and struct are part of the interface
        event Published();
        struct MyStruct {
            uint256 value;
        }
    }
    ```

1. Use named imports

    Named imports help readers understand what exactly is being used and where it is originally declared.

    YES:

    ```solidity
    import {Contract} from "./contract.sol"
    ```

    NO:

    ```solidity
    import "./contract.sol"
    ```

    For convenience, named imports do not have to be used in test files.

1. Return values are generally not named, unless they are not immediately clear or there are multiple return values.

    ```solidity
    function expiration() public view returns (uint256) { // Good
    function hasRole() public view returns (bool isMember, uint32 currentDelay) { // Good
    ```

1. Unchecked arithmetic blocks should contain comments explaining why overflow is guaranteed not to happen. If the reason is immediately apparent from the line above the unchecked block, the comment may be omitted.

1. Interface names should have a capital I prefix.

1. Prefer custom errors over require strings.

    Custom errors are usually more gas efficient. The exception to this is `require` statements in the constructor or for situations that should never happen(e.g. invariants that should never be violated but we still put a guard in the code).

    YES:

    ``` solidity
    uint256 public balance;
    error InsufficientBalance(uint256 balance, uint256 required);

    function withdraw(uint256 amount) external {
        if (amount > balance) revert InsufficientBalance(balance, amount);
        balance -= amount;
    }
    ```

    NO:

    ```solidity
    uint256 public balance;

    function withdraw(uint256 amount) external {
        require(amount <= balance, "Insufficient balance");
        balance -= amount;
    }
    ```

## Testing

TODO: Add testing guide

## Acknowledgements

This style guide was inspired by the following sources:

- [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)
- [Coinbase Style Guide](https://github.com/coinbase/solidity-style-guide/blob/main/README.md)
- [OpenZeppelin Contracts Solidity Conventions](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/GUIDELINES.md#solidity-conventions)
