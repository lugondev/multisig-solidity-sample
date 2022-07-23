// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MasterOwners is ContextUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    EnumerableSetUpgradeable.AddressSet _owners;
    address public masterOwner;

    EnumerableSet.UintSet pendingTxs;
    EnumerableSet.UintSet executedTxs;
    EnumerableSet.UintSet cancelTxs;

    event SetOwner(address indexed newOwner);
    event RevokeOwner(address indexed owner);
    event RenounceOwnership(address indexed owner);
    event RenounceMasterOwnership(address indexed owner);
    event MasterOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event ExecuteTransaction(uint256 indexed _id);
    event CancelTransaction(uint256 indexed _id);
    event SubmitTransaction(uint256 indexed _id, address _target, bytes _data);

    Counters.Counter private _transactionId;
    enum TxStatus {
        PENDING,
        SUCCESS,
        CANCEL
    }

    struct Transaction {
        address submitter;
        address target;
        bytes data;
        TxStatus status;
    }

    mapping(uint256 => Transaction) public transactions;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() public initializer {
        __Context_init_unchained();

        masterOwner = _msgSender();
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function ownerByIndex(uint256 index) public view virtual returns (address) {
        return _owners.at(index);
    }

    function isOwner(address _user) public view virtual returns (bool) {
        return _owners.contains(_user);
    }

    function totalOwner() public view virtual returns (uint256) {
        return _owners.length();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            _owners.contains(_msgSender()) || _msgSender() == masterOwner,
            "Ownable: caller is not the owner"
        );
        _;
    }

    modifier onlyMasterOwner() {
        require(
            masterOwner == _msgSender(),
            "Ownable: caller is not the master owner"
        );
        _;
    }

    modifier noPendingTx() {
        require(totalPendingTxs() == 0, "call without any pending txs");
        _;
    }

    modifier isPendingTransaction(uint256 _id) {
        require(
            _id > 0 &&
                _id <= _transactionId.current() &&
                pendingTxs.contains(_id),
            "invalid transaction id"
        );
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _owners.remove(_msgSender());

        emit RenounceOwnership(_msgSender());
    }

    function renounceMasterOwnership() public virtual onlyMasterOwner {
        masterOwner = address(0);

        emit RenounceMasterOwnership(_msgSender());
    }

    function transferMasterOwnership(address newOwner)
        public
        virtual
        onlyMasterOwner
    {
        require(
            _owners.contains(newOwner),
            "Ownable: new master owner is current owner"
        );

        masterOwner = newOwner;
        _owners.remove(newOwner);

        emit MasterOwnershipTransferred(masterOwner, newOwner);
    }

    function removeOwner(address owner) public virtual onlyMasterOwner {
        require(_owners.contains(owner), "Ownable: address is not owner");

        _owners.remove(owner);

        emit RevokeOwner(owner);
    }

    function addOwner(address newOwner) public virtual onlyMasterOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        _owners.add(newOwner);

        emit SetOwner(newOwner);
    }

    function totalPendingTxs() public view returns (uint256) {
        return pendingTxs.length();
    }

    function getPendingTxByIndex(uint256 _index)
        public
        view
        returns (uint256 txId, Transaction memory)
    {
        txId = pendingTxs.at(_index);
        return (txId, transactions[txId]);
    }

    function totalExecutedTxs() public view returns (uint256) {
        return executedTxs.length();
    }

    function getExecutedTxByIndex(uint256 _index)
        public
        view
        returns (uint256 txId, Transaction memory)
    {
        txId = executedTxs.at(_index);
        return (txId, transactions[txId]);
    }

    function totalCancelTxs() public view returns (uint256) {
        return cancelTxs.length();
    }

    function getCancelTxByIndex(uint256 _index)
        public
        view
        returns (uint256 txId, Transaction memory)
    {
        txId = cancelTxs.at(_index);
        return (txId, transactions[txId]);
    }

    function currentTransactionId() public view returns (uint256) {
        return _transactionId.current();
    }

    function submitTransaction(address _target, bytes memory _data)
        public
        onlyOwner
    {
        _transactionId.increment();
        transactions[currentTransactionId()] = Transaction({
            submitter: msg.sender,
            target: _target,
            data: _data,
            status: TxStatus.PENDING
        });
        pendingTxs.add(currentTransactionId());

        emit SubmitTransaction(currentTransactionId(), _target, _data);
    }

    function cancelTransaction(uint256 _id)
        public
        isPendingTransaction(_id)
        onlyOwner
    {
        Transaction storage transactionData = transactions[_id];
        require(
            transactionData.submitter == msg.sender ||
                msg.sender == masterOwner ||
                !isOwner(transactionData.submitter),
            "cannot cancel other's tx"
        );

        pendingTxs.remove(_id);
        cancelTxs.add(_id);
        transactionData.status = TxStatus.CANCEL;

        emit CancelTransaction(_id);
    }

    function executeTransaction(uint256 _id)
        public
        isPendingTransaction(_id)
        onlyMasterOwner
    {
        Transaction storage transactionData = transactions[_id];
        pendingTxs.remove(_id);

        (bool success, ) = transactionData.target.call(transactionData.data);
        require(success, "execute: failed!!!");

        executedTxs.add(_id);
        transactionData.status = TxStatus.SUCCESS;

        emit ExecuteTransaction(_id);
    }
}
