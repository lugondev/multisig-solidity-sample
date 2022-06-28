// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MultiSigExecute {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    event Deposit(address indexed _sender, uint256 _amount, uint256 _balance);
    event ExecuteTransaction(uint256 indexed _id);
    event CancelTransaction(uint256 indexed _id);
    event SubmitTransaction(uint256 indexed _id, address _target, bytes _data);
    event RevokeTransaction(uint256 indexed _id);
    event ConfirmTransaction(uint256 indexed _id);
    event RevokeOwner(address indexed _account);
    event AddOwner(address indexed _account);
    event UpdateWeight(uint256 _newWeight);

    EnumerableSet.AddressSet owners;
    EnumerableSet.UintSet pendingTxs;
    EnumerableSet.UintSet executedTxs;
    EnumerableSet.UintSet cancelTxs;

    uint256 public weight;
    Counters.Counter private _transactionId;

    struct Transaction {
        address submitter;
        address target;
        bytes data;
        uint256 confirmations;
    }

    mapping(uint256 => Transaction) public transactions;

    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    constructor(address[] memory _owners, uint256 _weight) {
        require(
            _owners.length > 2,
            "the number of owners must be greater than 2"
        );
        require(
            _weight > 1 && _weight <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner(owner), "owner not unique");

            owners.add(owner);
        }

        weight = _weight;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "not owner");
        _;
    }

    modifier callYourSelf() {
        require(msg.sender == address(this), "only call yourself");
        _;
    }

    modifier noPendingTx() {
        require(totalPendingTxs() == 0, "call without any pending txs");
        _;
    }

    modifier isCurrentTransaction(uint256 _id) {
        require(
            _id > 0 &&
                _id <= _transactionId.current() &&
                pendingTxs.contains(_id),
            "invalid transaction id"
        );
        _;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function addOwner(address _account) public callYourSelf noPendingTx {
        require(!isOwner(_account), "Owner is exists.");
        require(
            (totalOwner() + 1) / 2 <= weight,
            "Weight is too low. Increase weight first"
        );
        owners.add(_account);

        emit AddOwner(_account);
    }

    function removeOwner(address _account) public callYourSelf noPendingTx {
        require(isOwner(_account), "Owner is not exists.");
        require(
            totalOwner() > 3,
            "Not enough owner to confirm the next transactions"
        );
        require(
            totalOwner() - 1 >= weight,
            "Not enough weight to verify the next transactions"
        );
        owners.remove(_account);

        emit RevokeOwner(_account);
    }

    function updateWeight(uint256 _weight) public callYourSelf noPendingTx {
        require(
            _weight > 1 && _weight <= totalOwner(),
            "invalid number of required confirmations"
        );

        weight = _weight;
        emit UpdateWeight(_weight);
    }

    function isOwner(address _user) public view returns (bool) {
        return owners.contains(_user);
    }

    function totalOwner() public view returns (uint256) {
        return owners.length();
    }

    function getOwnerByIndex(uint256 _index) public view returns (address) {
        return owners.at(_index);
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
            confirmations: 0
        });
        pendingTxs.add(currentTransactionId());

        emit SubmitTransaction(currentTransactionId(), _target, _data);
    }

    function revokeTransaction(uint256 _id)
        public
        isCurrentTransaction(_id)
        onlyOwner
    {
        require(isConfirmed[_id][msg.sender], "must confirm first");
        Transaction storage transactionData = transactions[_id];
        transactionData.confirmations--;
        isConfirmed[_id][msg.sender] = false;

        emit RevokeTransaction(_id);
    }

    function confirmTransaction(uint256 _id)
        public
        isCurrentTransaction(_id)
        onlyOwner
    {
        require(
            !isConfirmed[_id][msg.sender],
            "you confirmed this transaction"
        );
        Transaction storage transactionData = transactions[_id];
        transactionData.confirmations++;
        isConfirmed[_id][msg.sender] = true;

        emit ConfirmTransaction(_id);
    }

    function cancelTransaction(uint256 _id)
        public
        isCurrentTransaction(_id)
        onlyOwner
    {
        Transaction memory transactionData = transactions[_id];
        if (isOwner(transactionData.submitter)) {
            require(
                transactionData.submitter == msg.sender,
                "invalid submitter"
            );
            require(
                transactionData.confirmations == 0,
                "invalid transaction status"
            );
        }

        pendingTxs.remove(_id);
        cancelTxs.add(_id);

        emit CancelTransaction(_id);
    }

    function executeTransaction(uint256 _id) public isCurrentTransaction(_id) {
        Transaction memory transactionData = transactions[_id];
        require(
            isOwner(transactionData.submitter),
            "summiter is revoked owner"
        );
        require(
            transactionData.confirmations >= weight,
            "not enough confirmations"
        );

        pendingTxs.remove(_id);

        (bool success, ) = transactionData.target.call(transactionData.data);
        require(success, "execute: failed!!!");

        executedTxs.add(_id);

        emit ExecuteTransaction(_id);
    }
}
