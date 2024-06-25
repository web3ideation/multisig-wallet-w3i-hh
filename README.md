## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Third-Party Libraries

This project includes code from the following open-source project(s):

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) - Licensed under the MIT License.
- further see the "third-party-licenses" folder


<br><br><br><br><br>





Next steps:

 have two different numconfirmationrequired for normal transactions and adding/deleting users (does that make sense?) - leichte entscheidungen 50+1 und schwere 2/3 mehrheit
    -> two nums implemented.****
    -> have them automatically and alwyas at 50+1 and 2/3 **continue here****see cGPT**

 add a function to change the numConfirmationsRequired if ALL multisig owners confirm. make sure tho that it cant be higher than how many multisigowners exist at the given time. 
 Also doublecheck that if a multisigowner gets deleted that the numconfirmation gets reduced in case otherwise there would be more confirmations required than multisigowners exist.

 add a function where the multisigOwner who submitted a transaction is able to cancel/delete it anytime before it has been executed. - i dont think thats necessary, since one can just revoke their confirmation.

 have two different numconfirmationrequired for normal transactions and adding/deleting users (does that make sense?) - leichte entscheidungen 50+1 und schwere 2/3 mehrheit

 enhance the event information as explained by cGPT above

 muss ich noch irgendwelche getter und setter funktionen schreiben?

 Gas Efficiency: Using assembly for decoding is efficient, but ensure it’s necessary for the data format you expect. Solidity's abi.decode could be used if the data format is consistent.

Error Handling: Add more descriptive error messages for edge cases, such as invalid data formats or failed transactions.

natspec nochmal machen lassen weil ich ja sachen geändert hatte

 using an enum instead of a boolean for isERC721 can make the code more readable and maintainable. Enums provide a clearer understanding of the possible states and can be extended more easily in the future if needed.

 check if the 2/3 and 50%+1 really works for 2 3 4 5 6 7 8 99 999 owners 