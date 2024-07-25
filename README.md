## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Third-Party Libraries

This project includes code from the following open-source project(s):

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) - Licensed under the MIT License.
- further see the "third-party-licenses" folder


<br><br><br><br><br>





Next steps:

 have two different numconfirmationrequired for normal transactions and adding/deleting users (does that make sense?) - leichte entscheidungen 50+1 und schwere 2/3 mehrheit
    -> two nums implemented.✅
    -> have them automatically and alwyas at 50+1 and 2/3✅

 add a function to change the numConfirmationsRequired if ALL multisig owners confirm. make sure tho that it cant be higher than how many multisigowners exist at the given time. -> Since I use the automated logic it would make more sense to use the Diamond structure to make the whole contract and thus the logic itself upgradable ✅
 Also doublecheck that if a multisigowner gets deleted that the numconfirmation gets reduced in case otherwise there would be more confirmations required than multisigowners exist. -> added note for that in the code ✅

 add a function where the multisigOwner who submitted a transaction is able to cancel/delete it anytime before it has been executed. - i dont think thats necessary, since one can just revoke their confirmation. ✅

 have two different numconfirmationrequired for normal transactions and adding/deleting users (does that make sense?) - leichte entscheidungen 50+1 und schwere 2/3 mehrheit ✅

 ❌ bei 2 ownern reicht die confirmation von einem um tokens zu transferieren also 50% +1 funktioniert nicht richtig

 enhance the event information as explained by cGPT above

 muss ich noch irgendwelche getter und setter funktionen schreiben?

 Gas Efficiency: Using assembly for decoding is efficient, but ensure it’s necessary for the data format you expect. Solidity's abi.decode could be used if the data format is consistent.

Error Handling: Add more descriptive error messages for edge cases, such as invalid data formats or failed transactions.

natspec nochmal machen lassen weil ich ja sachen geändert hatte

 using an enum instead of a boolean for isERC721 can make the code more readable and maintainable. Enums provide a clearer understanding of the possible states and can be extended more easily in the future if needed.

 check if the 2/3 and 50%+1 really works for 2 3 4 5 6 7 8 99 999 owners 

 Reentrancy Guard: Use OpenZeppelin's ReentrancyGuard modifier for public and external functions to protect against reentrancy attacks. You already inherit from ReentrancyGuard, so applying its modifier to susceptible functions is advisable.

 Add that with submitting there will automatically the confirm function be called (is that necessary?)



 Remix Notes:

 3 Owners:
 0 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
 1 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
 2 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db


Abstimmung 1: Send 0.1 ETH to 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 (Owner 2)
Worked

Abstimmung 2: Send 0.3 ETH to 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C (random third person)
Worked

Abstimmung 3: add owner 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
❌--> Ok i can submit the addOwner but when the other two existing owners want to confirm i get a "Transaction failed"

Abstimmung 4: remove owner 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

Abstimmung 5: ERC20 verschicken lassen

Abstimmung 6: ERC721 verschicken lassen

How to use:
to deploy do not send ETH with it but put all the owners in [] seperated with , 
to submitTransaction write the value in WEI and if only ETH write 0x for data





ok jetzt mal das ganze in hardhat testen ob ich da mit dem simplified contract das gleiche problem habe oder ob es an remix liegt. wenn nicht dann schauen ob die erc721 und erc20 executes gehen. wenn ja dann einfach für die add und remove owner mit highlevel calls umprogrammieren - einfach erstmal wieder den hardhat node zum laufen bringen und dann statt mit der console mit scripten mit dem contract interargieren. vlt kann ich später mal  hardhat durch foundry ablösen - vielleicht auch einfach mal mit cGPT komplett hardhat neu einrichten, also checken ob die version passt und dann neue projekt anlegen - remix sepolia funktioniert auch nicht, also wird hardhat wohl auch nicht funktionieren. das problem ist also im contract selbst. als nächstes schauen ob die erc721 und erc20 executes gehen. wenn ja dann einfach für die add und remove owner mit highlevel calls umprogrammieren
-> Also erc20 funktioniert, es ist wohl nur das problem mit dem internen call. 