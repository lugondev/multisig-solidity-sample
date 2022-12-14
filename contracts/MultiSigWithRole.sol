// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./common/MultiSend.sol";
import "./common/SelfAuthorized.sol";

contract MultiSigWithRole is MultiSend, SelfAuthorized {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    event UpdateWeight(uint256 _newWeight);
    event Deposit(address indexed _sender, uint256 _amount);
    event Withdraw(address indexed _receiver, uint256 _amount);
    event ExecuteTransaction(uint256 indexed _id);
    event CancelTransaction(uint256 indexed _id);
    event SubmitTransaction(
        uint256 indexed _id,
        address _target,
        bytes _data,
        uint256 _deadline,
        string _note
    );
    event RevokeTransaction(uint256 indexed _id);
    event ConfirmTransaction(uint256 indexed _id);
    event RevokeOwner(address _account);
    event RevokeSubmitter(address _account);
    event AddOwner(address _account);
    event AddSubmitter(address _account);

    EnumerableSet.AddressSet submitters;
    EnumerableSet.AddressSet owners;
    EnumerableSet.UintSet pendingTxs;
    EnumerableSet.UintSet executedTxs;
    EnumerableSet.UintSet cancelTxs;
    Counters.Counter private _transactionId;

    enum TxStatus {
        PENDING,
        SUCCESS,
        CANCEL
    }
    enum Role {
        SUBMITTER,
        OWNER
    }

    struct Transaction {
        address submitter;
        address target;
        bytes data;
        string note;
        uint256 deadline;
        uint256 confirmations;
        TxStatus status;
    }

    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) private _isConfirmed;
    uint256 defaultDeadline = 1 days;
    uint256 public weight;

    constructor(address[] memory _owners, uint256 _weight) {
        if (_owners.length == 0) {
            owners.add(msg.sender);
            weight = 1;
            return;
        }

        require(
            _weight >= 1 && _weight <= _owners.length,
            "invalid number of required confirmations"
        );
        require(
            (_owners.length / 2) + 1 <= _weight,
            "weight is too low to ensure safety"
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
        require(isOwner(msg.sender), "only called by owner");
        _;
    }

    modifier validSubmitter() {
        require(
            isSubmitter(msg.sender) || isOwner(msg.sender),
            "you do not have permission to submit transaction"
        );
        _;
    }

    modifier isPendingTransaction(uint256 _id) {
        require(
            _id > 0 &&
                _id <= _transactionId.current() &&
                pendingTxs.contains(_id),
            "this transaction is not pending"
        );
        _;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function updateWeight(uint256 _weight) public authorized {
        require(totalPendingTxs() == 0, "only call without any pending txs");
        require(totalOwner() >= _weight, "weight is too high to ensure safety");
        require(
            (totalOwner() / 2) + 1 <= _weight,
            "weight is too low to ensure safety"
        );

        weight = _weight;
        emit UpdateWeight(_weight);
    }

    function addRole(address _account, Role _role) public authorized {
        if (_role == Role.OWNER) {
            require(
                totalPendingTxs() == 0,
                "only call without any pending txs"
            );
            require(!isOwner(_account), "owner is exists");
            require(
                ((totalOwner() + 1) / 2) + 1 <= weight,
                "weight is too low to ensure safety"
            );
            owners.add(_account);

            emit AddOwner(_account);
        } else {
            require(!isSubmitter(_account), "submitter is exists");
            submitters.add(_account);

            emit AddSubmitter(_account);
        }
    }

    function removeRole(address _account, Role _role) public authorized {
        if (_role == Role.OWNER) {
            require(
                totalPendingTxs() == 0,
                "only call without any pending txs"
            );
            require(isOwner(_account), "owner is not exists");
            if (totalOwner() - 1 < weight) {
                weight = totalOwner() - 1;
            }
            owners.remove(_account);

            emit RevokeOwner(_account);
        } else {
            require(isSubmitter(_account), "submitter is not exists");
            submitters.remove(_account);

            emit RevokeSubmitter(_account);
        }
    }

    function isOwner(address _user) public view returns (bool) {
        return owners.contains(_user);
    }

    function isSubmitter(address _user) public view returns (bool) {
        return submitters.contains(_user);
    }

    function totalOwner() public view returns (uint256) {
        return owners.length();
    }

    function totalSubmitter() public view returns (uint256) {
        return submitters.length();
    }

    function getOwnerByIndex(uint256 _index) public view returns (address) {
        return owners.at(_index);
    }

    function getSubmitterByIndex(uint256 _index) public view returns (address) {
        return submitters.at(_index);
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

    function isConfirmed(uint256 _id, address _user)
        public
        view
        returns (bool)
    {
        return _isConfirmed[_id][_user];
    }

    function currentTransactionId() public view returns (uint256) {
        return _transactionId.current();
    }

    function submitTransaction(
        address _target,
        bytes memory _data,
        uint256 _deadline,
        string memory _note
    ) public validSubmitter {
        if (_deadline == 0) {
            _deadline = defaultDeadline + block.timestamp;
        } else {
            require(_deadline > block.timestamp, "invalid deadline");
        }

        _transactionId.increment();

        transactions[currentTransactionId()] = Transaction({
            submitter: msg.sender,
            target: _target,
            data: _data,
            confirmations: 0,
            deadline: _deadline,
            note: _note,
            status: TxStatus.PENDING
        });
        pendingTxs.add(currentTransactionId());

        emit SubmitTransaction(
            currentTransactionId(),
            _target,
            _data,
            _deadline,
            _note
        );
    }

    function revokeTransaction(uint256 _id)
        public
        isPendingTransaction(_id)
        onlyOwner
    {
        require(
            _isConfirmed[_id][msg.sender],
            "you have not confirmed this tx"
        );

        Transaction storage transactionData = transactions[_id];
        transactionData.confirmations--;
        _isConfirmed[_id][msg.sender] = false;

        emit RevokeTransaction(_id);
    }

    function confirmTransaction(uint256 _id)
        public
        isPendingTransaction(_id)
        onlyOwner
    {
        require(
            !_isConfirmed[_id][msg.sender],
            "you have already confirmed this tx"
        );

        Transaction storage transactionData = transactions[_id];
        transactionData.confirmations++;
        _isConfirmed[_id][msg.sender] = true;

        emit ConfirmTransaction(_id);
    }

    function cancelTransaction(uint256 _id)
        public
        isPendingTransaction(_id)
        validSubmitter
    {
        Transaction storage transactionData = transactions[_id];

        require(
            ((transactionData.submitter == msg.sender || isOwner(msg.sender)) &&
                transactionData.confirmations == 0) ||
                transactionData.deadline < block.timestamp,
            "can not cancel this tx"
        );

        pendingTxs.remove(_id);
        cancelTxs.add(_id);
        transactionData.status = TxStatus.CANCEL;

        emit CancelTransaction(_id);
    }

    function executeTransaction(uint256 _id)
        public
        payable
        isPendingTransaction(_id)
        validSubmitter
    {
        Transaction storage transactionData = transactions[_id];
        require(transactionData.deadline >= block.timestamp, "tx expired");
        require(
            isSubmitter(transactionData.submitter) ||
                isOwner(transactionData.submitter),
            "summitter is revoked by owner"
        );
        require(
            transactionData.confirmations >= weight,
            "not enough confirmations to executed"
        );

        pendingTxs.remove(_id);

        (bool success, ) = transactionData.target.call{value: msg.value}(
            transactionData.data
        );
        require(success, "execute: failed!!!");

        executedTxs.add(_id);
        transactionData.status = TxStatus.SUCCESS;

        emit ExecuteTransaction(_id);
    }

    function payment(
        address _token,
        address _receiver,
        uint256 _amount
    ) public authorized {
        require(_amount > 0, "amount must be greater than 0");

        if (_token == address(0)) {
            uint256 currentBalance = address(this).balance;
            require(currentBalance >= _amount, "insufficient balance");
            payable(_receiver).transfer(_amount);

            emit Withdraw(_receiver, _amount);
        } else {
            require(_transferToken(_token, _receiver, _amount));
        }
    }

    function multiSend(
        address _token,
        address[] memory _receivers,
        uint256[] memory _amounts
    ) public authorized {
        _multiSend(_token, _receivers, _amounts);
    }

    function multiSendTokens(
        address[] memory _tokens,
        address[] memory _receivers,
        uint256[] memory _amounts
    ) public authorized {
        _multiSendTokens(_tokens, _receivers, _amounts);
    }
}
