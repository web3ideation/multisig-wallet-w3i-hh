next steps:
24.05.24 Gnosis checken ob ich darauf aufbauen kann. Den contract verstehen und schauen was ich anpassen muss für uns. Checken ob ich ihn verwenden darf und ob ich licenses/mentions machen muss.

licence field package.json und sonst auch checken was ich da irgendwo hinzufügen muss damit das mit license passt


This is a detailed breakdown of the provided MultiSigWallet smart contract block by block:

### SPDX License Identifier and Pragma Directive
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
```
- **SPDX License Identifier:** Specifies the license under which the code is released.
- **Pragma Directive:** Specifies the version of Solidity compiler to use.

### Imports
```solidity
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
```
- **ReentrancyGuard:** Protects functions from reentrancy attacks.
- **IERC20 and IERC721:** Interfaces for interacting with ERC20 and ERC721 tokens respectively.

### Contract Definition and Events
```solidity
contract MultiSigWallet is ReentrancyGuard {
```
- **MultiSigWallet:** Main contract inheriting from `ReentrancyGuard`.

#### Events
```solidity
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
```
- **Events:** Log significant actions (deposits, submissions, confirmations, revocations, executions, owner additions/removals).

### State Variables
```solidity
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    Transaction[] public transactions;
```
- **Owners and Confirmation Requirements:** Tracks wallet owners and the required number of confirmations for a transaction.
- **Transaction Struct:** Holds details of each transaction.
- **Mappings:** Track which owners have confirmed transactions and the list of transactions.

### Modifiers
```solidity
    modifier onlyMultiSigOwner() {
        require(isOwner[msg.sender], "Not a multisig owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "Transaction already confirmed");
        _;
    }
```
- **Modifiers:** Ensure conditions are met before executing function logic (e.g., only owners can call certain functions, transaction must exist, not be executed or already confirmed).

### Constructor
```solidity
    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        require(_owners.length > 0, "Owners required");
        require(
            _numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,
            "Invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }
```
- **Constructor:** Initializes the contract with the list of owners and the required number of confirmations. Validates inputs to ensure they are correct.

### Fallback Function
```solidity
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
```
- **Fallback Function:** Allows the contract to receive Ether and logs deposits.

### Submit Transaction
```solidity
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyMultiSigOwner {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }
```
- **Submit Transaction:** Allows an owner to submit a transaction for confirmation by others. Adds the transaction to the list and logs it.

### Confirm Transaction
```solidity
    function confirmTransaction(
        uint256 _txIndex
    ) public onlyMultiSigOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);

        if (transaction.numConfirmations >= numConfirmationsRequired) {
            executeTransaction(_txIndex);
        }
    }
```
- **Confirm Transaction:** Allows an owner to confirm a submitted transaction. If enough confirmations are received, the transaction is executed.

### Execute Transaction
```solidity
    function executeTransaction(
        uint256 _txIndex
    ) internal onlyMultiSigOwner txExists(_txIndex) notExecuted(_txIndex) nonReentrant {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "Cannot execute transaction"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }
```
- **Execute Transaction:** Executes a confirmed transaction. Ensures reentrancy protection and that the transaction has the required confirmations.

### Revoke Confirmation
```solidity
    function revokeConfirmation(
        uint256 _txIndex
    ) public onlyMultiSigOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(isConfirmed[_txIndex][msg.sender], "Transaction not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }
```
- **Revoke Confirmation:** Allows an owner to revoke their confirmation for a transaction.

### Add Owner
```solidity
    function addOwner(address _newOwner) public onlyMultiSigOwner {
        bytes memory data = abi.encodeWithSignature("addOwnerInternal(address)", _newOwner);
        submitTransaction(address(this), 0, data);
    }
```
- **Add Owner:** Submits a transaction to add a new owner. Requires confirmation.

### Internal Add Owner
```solidity
    function addOwnerInternal(
        address _newOwner
    )
        public
        onlyMultiSigOwner
        txExists(transactions.length - 1)
        notExecuted(transactions.length - 1)
    {
        require(_newOwner != address(0), "Invalid owner");
        require(!isOwner[_newOwner], "Owner already exists");

        isOwner[_newOwner] = true;
        owners.push(_newOwner);

        emit OwnerAdded(_newOwner);
    }
```
- **Internal Add Owner:** Actually adds a new owner once the transaction is confirmed.

### Remove Owner
```solidity
    function removeOwner(address _owner) public onlyMultiSigOwner {
        bytes memory data = abi.encodeWithSignature("removeOwnerInternal(address)", _owner);
        submitTransaction(address(this), 0, data);
    }
```
- **Remove Owner:** Submits a transaction to remove an owner. Requires confirmation.

### Internal Remove Owner
```solidity
    function removeOwnerInternal(
        address _owner
    )
        public
        onlyMultiSigOwner
        txExists(transactions.length - 1)
        notExecuted(transactions.length - 1)
    {
        require(isOwner[_owner], "Not an owner");

        isOwner[_owner] = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }

        emit OwnerRemoved(_owner);
    }
```
- **Internal Remove Owner:** Actually removes an owner once the transaction is confirmed.

### Transfer ERC20 Tokens
```solidity
    function transferERC20(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) public onlyMultiSigOwner {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", _to, _amount);
        submitTransaction(_tokenAddress, 0, data);
    }
```
- **Transfer ERC20:** Submits a transaction to transfer ERC20 tokens.

### Transfer ERC721 Tokens
```solidity
    function transferERC721(
        address _tokenAddress,
        address _to,
        uint256 _tokenId
    ) public onlyMultiSigOwner {
        bytes memory data = abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256)",
            address(this),
            _to,
            _tokenId
        );
        submitTransaction(_tokenAddress, 0, data);
    }
```
- **Transfer ERC721:** Submits a transaction to transfer ERC

721 tokens.

This contract is a comprehensive multi-signature wallet that allows multiple owners to manage transactions, requiring a specified number of confirmations before executing them. It supports adding/removing owners and handling ERC20/ERC721 token transfers.






additional:


when multisigowners are added or deleted all pending transactions will be deleted to make sure that old pending malicous transactions cant get triggered with the help of new malicious multisigowners.
clearPendingTransactions Function:

This internal function deletes all pending transactions and emits a PendingTransactionsCleared event.
The function is called whenever an owner is added or removed to ensure all pending transactions are invalidated.
Modifications to addOwnerInternal and removeOwnerInternal:

After adding or removing an owner, the clearPendingTransactions function is called to clear all pending transactions.
Summary:
When a new multisig owner is added or an existing owner is removed, the clearPendingTransactions function deletes all pending transactions.
This approach ensures that no previously submitted transactions can be confirmed or executed by newly added owners, thereby preventing potential security risks.
By doing this, you maintain a zero-trust environment where changes to the owner set do not allow exploitation of old, unconfirmed transactions.


 add a function to change the numConfirmationsRequired if ALL multisig owners confirm. make sure tho that it cant be higher than how many multisigowners exist at the given time. Also doublecheck that if a multisigowner gets deleted that the numconfirmation gets reduced in case otherwise there would be more confirmations required than multisigowners exist.

 add a function where the multisigOwner who submitted a transaction is able to cancel/delete it anytime before it has been executed.

 have two different numconfirmationrequired for normal transactions and adding/deleting users (does that make sense?)







 cGPT hat noch vorschläge um den contract sicherer zu machen damit das voten nicht umgangen/manipuliert werden kann:

 To ensure that the multisig wallet operates securely and that no single owner can bypass the multisig mechanism, I added several safeguards to the contract. Here’s a detailed explanation of each safeguard added:

### 1. Controlled Execution

#### `executeTransaction` Function:
This function is responsible for executing transactions that have been confirmed by the required number of multisig owners.

**Key Points:**
- **Only Executed with Sufficient Confirmations:**
  ```solidity
  require(
      transaction.numConfirmations >= numConfirmationsRequired,
      "Cannot execute transaction"
  );
  ```
  This ensures that a transaction can only be executed if it has received the required number of confirmations.

- **Prevent Re-execution:**
  ```solidity
  require(!transactions[_txIndex].executed, "Transaction already executed");
  transaction.executed = true;
  ```
  This ensures that a transaction can only be executed once.

- **Execution Call:**
  ```solidity
  (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
  require(success, "Transaction failed");
  ```
  This low-level call executes the transaction. It’s a direct call to the target contract with the specified data and value.

### 2. Internal Execution Functions

To further safeguard the transfer of ERC20 and ERC721 tokens, I added internal functions specifically for these types of transfers. These functions can only be called from within the contract, ensuring they follow the multisig process.

#### ERC20 Transfer:
```solidity
function executeERC20Transfer(address _token, address _to, uint256 _amount) internal {
    IERC20(_token).transfer(_to, _amount);
}
```
- **Internal Use Only:** This function is `internal`, meaning it can only be called from within the contract.
- **Direct Transfer Call:** It uses the `IERC20` interface to call the `transfer` function on the specified token contract.

#### ERC721 Transfer:
```solidity
function executeERC721Transfer(address _token, address _from, address _to, uint256 _tokenId) internal {
    IERC721(_token).safeTransferFrom(_from, _to, _tokenId);
}
```
- **Internal Use Only:** This function is `internal`, meaning it can only be called from within the contract.
- **Direct Transfer Call:** It uses the `IERC721` interface to call the `safeTransferFrom` function on the specified token contract.

### 3. Clearing Pending Transactions

To ensure that no pending transactions can be confirmed by a newly added owner, I added a function to clear all pending transactions whenever the set of owners is changed.

#### Clear Pending Transactions:
```solidity
function clearPendingTransactions() internal {
    delete transactions;
    emit PendingTransactionsCleared();
}
```
- **Delete All Transactions:** This function deletes all pending transactions by clearing the `transactions` array.
- **Emit Event:** It emits an event to notify that all pending transactions have been cleared.

### 4. Adding and Removing Owners

To ensure security during the addition or removal of owners, the contract clears all pending transactions before adding a new owner or after removing an existing owner.

#### Add Owner:
```solidity
function addOwnerInternal(address _newOwner) public onlyMultiSigOwner txExists(transactions.length - 1) notExecuted(transactions.length - 1) {
    require(_newOwner != address(0), "Invalid owner");
    require(!isOwner[_newOwner], "Owner already exists");

    // Clear pending transactions before adding the new owner
    clearPendingTransactions();

    // Add the new owner
    isOwner[_newOwner] = true;
    owners.push(_newOwner);

    emit OwnerAdded(_newOwner);
}
```
- **Clear Pending Transactions:** Before adding the new owner, all pending transactions are cleared.
- **Add the New Owner:** The new owner is then added to the list of owners.

#### Remove Owner:
```solidity
function removeOwnerInternal(address _owner) public onlyMultiSigOwner txExists(transactions.length - 1) notExecuted(transactions.length - 1) {
    require(isOwner[_owner], "Not an owner");

    // Clear pending transactions before removing the owner
    clearPendingTransactions();

    isOwner[_owner] = false;
    for (uint256 i = 0; i < owners.length; i++) {
        if (owners[i] == _owner) {
            owners[i] = owners[owners.length - 1];
            owners.pop();
            break;
        }
    }

    emit OwnerRemoved(_owner);
}
```
- **Clear Pending Transactions:** Before removing the owner, all pending transactions are cleared.
- **Remove the Owner:** The owner is then removed from the list of owners.

### Summary

The following safeguards have been added to the contract to ensure its security:

1. **Controlled Execution:** Transactions can only be executed if they have the required number of confirmations, and each transaction can only be executed once.
2. **Internal Execution Functions:** Specific functions for transferring ERC20 and ERC721 tokens are internal, ensuring they can only be called through the multisig process.
3. **Clearing Pending Transactions:** Pending transactions are cleared whenever the set of owners is changed to prevent new owners from confirming old transactions.
4. **Secure Addition and Removal of Owners:** The contract clears pending transactions before adding or removing an owner, ensuring no pending transactions can be confirmed by a new or remaining owner.

These measures ensure that no single owner can bypass the multisig mechanism and that all asset transfers are securely managed through the multisig process.







To update the events to clearly specify which ERC20 token and amount are being sent without modifying the `submitTransaction` function, you can decode the data just before emitting the events in the relevant functions.

### Updating the Events to Decode and Include ERC20 Token and Amount

To achieve this, we'll decode the `transaction.data` just before emitting the `SubmitTransaction` and `ExecuteTransaction` events.

Here's how to do it:

### Step 1: Modify the Events

First, modify the events to include `tokenAddress` and `amount`.

```solidity
event SubmitTransaction(
    address indexed owner,
    uint256 indexed txIndex,
    address indexed to,
    uint256 value,
    bytes data,
    address tokenAddress,
    uint256 amount
);

event ExecuteTransaction(
    address indexed owner,
    uint256 indexed txIndex,
    address indexed to,
    uint256 value,
    bytes data,
    address tokenAddress,
    uint256 amount
);
```

### Step 2: Decode the Data in `submitTransaction`

Add the logic to decode the data inside the `submitTransaction` function just before emitting the event:

```solidity
function submitTransaction(
    address _to,
    uint256 _value,
    bytes memory _data
) public onlyMultiSigOwner {
    uint256 txIndex = transactions.length;

    transactions.push(
        Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        })
    );

    // Decode the data to extract the token address and amount
    (address tokenAddress, uint256 amount) = decodeERC20TransferData(_data);

    emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data, tokenAddress, amount);
}
```

### Step 3: Decode the Data in `executeTransaction`

Add the logic to decode the data inside the `executeTransaction` function just before emitting the event:

```solidity
function executeTransaction(uint256 _txIndex)
    internal
    onlyMultiSigOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    nonReentrant
{
    Transaction storage transaction = transactions[_txIndex];

    require(
        transaction.numConfirmations >= numConfirmationsRequired,
        "Cannot execute transaction"
    );

    transaction.executed = true;

    (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
    require(success, "Transaction failed");

    // Decode the data to extract the token address and amount
    (address tokenAddress, uint256 amount) = decodeERC20TransferData(transaction.data);

    emit ExecuteTransaction(msg.sender, _txIndex, transaction.to, transaction.value, transaction.data, tokenAddress, amount);
}
```

### Step 4: Implement the Decoding Function

Implement the `decodeERC20TransferData` function to decode the encoded data and extract the token address and amount:

```solidity
function decodeERC20TransferData(bytes memory data) internal pure returns (address tokenAddress, uint256 amount) {
    // Assuming the data follows the structure of an ERC20 transfer call
    // "transfer(address,uint256)"
    bytes4 transferSelector = bytes4(keccak256("transfer(address,uint256)"));
    (bytes4 selector, address _to, uint256 _amount) = abi.decode(data, (bytes4, address, uint256));
    require(selector == transferSelector, "Invalid selector");

    return (_to, _amount);
}
```
