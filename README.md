## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Third-Party Libraries

This project includes code from the following open-source project(s):

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) - Licensed under the MIT License.
- further see the "third-party-licenses" folder




<br><br><br><br><br>

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



<br><br><br><br><br>





Next steps:

 add a function to change the numConfirmationsRequired if ALL multisig owners confirm. make sure tho that it cant be higher than how many multisigowners exist at the given time. Also doublecheck that if a multisigowner gets deleted that the numconfirmation gets reduced in case otherwise there would be more confirmations required than multisigowners exist.

 add a function where the multisigOwner who submitted a transaction is able to cancel/delete it anytime before it has been executed.

 have two different numconfirmationrequired for normal transactions and adding/deleting users (does that make sense?) - leichte entscheidungen 50+1 und schwere 2/3 mehrheit

 enhance the event information as explained by cGPT above

 muss ich noch irgendwelche getter und setter funktionen schreiben?