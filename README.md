## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Third-Party Libraries

This project includes code from the following open-source project(s):

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) - Licensed under the MIT License.
- further see the "third-party-licenses" folder


<br><br><br><br><br>





Next steps:

 add a function to change the numConfirmationsRequired if ALL multisig owners confirm. make sure tho that it cant be higher than how many multisigowners exist at the given time. Also doublecheck that if a multisigowner gets deleted that the numconfirmation gets reduced in case otherwise there would be more confirmations required than multisigowners exist.

 add a function where the multisigOwner who submitted a transaction is able to cancel/delete it anytime before it has been executed.

 have two different numconfirmationrequired for normal transactions and adding/deleting users (does that make sense?) - leichte entscheidungen 50+1 und schwere 2/3 mehrheit

 enhance the event information as explained by cGPT above

 muss ich noch irgendwelche getter und setter funktionen schreiben?

 Gas Efficiency: Using assembly for decoding is efficient, but ensure it’s necessary for the data format you expect. Solidity's abi.decode could be used if the data format is consistent.

Error Handling: Add more descriptive error messages for edge cases, such as invalid data formats or failed transactions.

natspec nochmal machen lassen weil ich ja sachen geändert hatte