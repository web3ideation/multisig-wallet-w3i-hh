// SPDX-License-Identifier: MIT
// This file is part of the MultiSigWallet project.
// Portions of this code are derived from the OpenZeppelin Contracts library.
// OpenZeppelin Contracts are licensed under the MIT License.
// See the LICENSE file for more details.
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title MultiSigWallet
 * @dev A multisig wallet contract that requires multiple confirmations for transactions, including managing owners.
 */
contract MultiSigWallet is ReentrancyGuard {
    /// @notice Emitted when a deposit is made.
    /// @param sender The address that sent the deposit.
    /// @param amount The amount of the deposit.
    /// @param balance The new balance of the wallet.
    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    /// @notice Emitted when a transaction is submitted.
    /// @param owner The address of the owner who submitted the transaction.
    /// @param txIndex The index of the submitted transaction.
    /// @param to The address to which the transaction is sent.
    /// @param value The amount of Ether sent in the transaction.
    /// @param data The data sent with the transaction.
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );

    /// @notice Emitted when a transaction is confirmed.
    /// @param owner The address of the owner who confirmed the transaction.
    /// @param txIndex The index of the confirmed transaction.
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);

    /// @notice Emitted when a confirmation is revoked.
    /// @param owner The address of the owner who revoked the confirmation.
    /// @param txIndex The index of the transaction for which the confirmation was revoked.
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);

    /// @notice Emitted when a transaction is executed.
    /// @param owner The address of the owner who executed the transaction.
    /// @param txIndex The index of the executed transaction.
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    /// @notice Emitted when an owner is added.
    /// @param owner The address of the owner added.
    event OwnerAdded(address indexed owner);

    /// @notice Emitted when an owner is removed.
    /// @param owner The address of the owner removed.
    event OwnerRemoved(address indexed owner);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired; // !!!W add a function to change the numConfirmationsRequired if ALL multisig owners confirm

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    Transaction[] public transactions;

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

    /**
     * @dev Constructor to initialize the contract.
     * @param _owners The addresses of the owners.
     * @param _numConfirmationsRequired The number of confirmations required for a transaction.
     */
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

    /**
     * @dev Fallback function to receive Ether.
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /**
     * @dev Submits a transaction to be confirmed by the owners.
     * @param _to The address to send the transaction to.
     * @param _value The amount of Ether to send.
     * @param _data The data to send with the transaction.
     */
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

    /**
     * @dev Confirms a submitted transaction.
     * @param _txIndex The index of the transaction to confirm.
     */
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

    /**
     * @dev Executes a confirmed transaction.
     * @param _txIndex The index of the transaction to execute.
     */
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

    /**
     * @dev Revokes a confirmation for a transaction.
     * @param _txIndex The index of the transaction to revoke confirmation for.
     */
    function revokeConfirmation(
        uint256 _txIndex
    )
        public
        onlyMultiSigOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    /* !!!W shouldnt i also add the isconfirmed modifier? */ {
        Transaction storage transaction = transactions[_txIndex];
        require(isConfirmed[_txIndex][msg.sender], "Transaction not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /**
     * @dev Adds a new multisig owner. This function needs to be confirmed by the required number of owners.
     * @param _newOwner The address of the new owner.
     */
    function addOwner(address _newOwner) public onlyMultiSigOwner {
        bytes memory data = abi.encodeWithSignature("addOwnerInternal(address)", _newOwner);
        submitTransaction(address(this), 0, data);
    }

    /**
     * @dev Internal function to add a new owner. Should only be called via a confirmed transaction.
     * @param _newOwner The address of the new owner.
     */
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

        // clearPendingTransactions(); // !!!W has to be here, right?

        isOwner[_newOwner] = true;
        owners.push(_newOwner);

        emit OwnerAdded(_newOwner);
    }

    /**
     * @dev Removes a multisig owner. This function needs to be confirmed by the required number of owners.
     * @param _owner The address of the owner to remove.
     */
    function removeOwner(address _owner) public onlyMultiSigOwner {
        bytes memory data = abi.encodeWithSignature("removeOwnerInternal(address)", _owner);
        submitTransaction(address(this), 0, data);
    }

    /**
     * @dev Internal function to remove an owner. Should only be called via a confirmed transaction.
     * @param _owner The address of the owner to remove.
     */
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

    /**
     * @dev Submits a transaction to transfer ERC20 tokens.
     * @param _tokenAddress The address of the ERC20 token contract.
     * @param _to The address to send the tokens to.
     * @param _amount The amount of tokens to send.
     */
    function transferERC20(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) public onlyMultiSigOwner {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", _to, _amount);
        submitTransaction(_tokenAddress, 0, data);
    }

    /**
     * @dev Submits a transaction to transfer ERC721 tokens.
     * @param _tokenAddress The address of the ERC721 token contract.
     * @param _to The address to send the token to.
     * @param _tokenId The ID of the token to send.
     */
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
}
